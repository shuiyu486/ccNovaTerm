[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- Read JSON from stdin as raw bytes, decode with UTF-8 ---
$inputJson = ""
$rawBytes = $null
try {
    $stream = [Console]::OpenStandardInput()
    $ms = New-Object System.IO.MemoryStream
    $stream.CopyTo($ms)
    $rawBytes = $ms.ToArray()
    $ms.Close()
} catch {}

if ($rawBytes -and $rawBytes.Length -gt 0) {
    $inputJson = [System.Text.Encoding]::UTF8.GetString($rawBytes)
}

if (-not $inputJson) { try { $inputJson = $input | Out-String } catch {} }
if (-not $inputJson.Trim()) { exit }

# --- Parse JSON using .NET JavaScriptSerializer (bypasses PS5.1 ConvertFrom-Json encoding bugs) ---
Add-Type -AssemblyName System.Web.Extensions -EA SilentlyContinue
$data = $null
try {
    $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $ser.MaxJsonLength = [int]::MaxValue
    $data = $ser.DeserializeObject($inputJson)
} catch {}

if (-not $data) {
	Write-Host "No data from Claude Code"
	exit
}

# --- Extract values from Dictionary<string,object> ---
$model = if ($data['model'] -and $data['model']['display_name']) { $data['model']['display_name'] } else { "unknown" }
$ctxPct = if ($data['context_window'] -and $data['context_window']['used_percentage']) { [math]::Floor([double]$data['context_window']['used_percentage']) } else { 0 }
$effort = if ($data['effort'] -and $data['effort']['level']) { $data['effort']['level'] } else { "" }
$ctxSize = if ($data['context_window'] -and $data['context_window']['context_window_size']) { [long]$data['context_window']['context_window_size'] } else { 0 }
$inputTokens = if ($data['context_window'] -and $data['context_window']['total_input_tokens']) { [long]$data['context_window']['total_input_tokens'] } else { 0 }
$outputTokens = if ($data['context_window'] -and $data['context_window']['total_output_tokens']) { [long]$data['context_window']['total_output_tokens'] } else { 0 }

# --- Find claude.exe PID for session tracking ---
$sessionPid = 0
try {
    $curPid = $PID; $depth = 0
    while ($depth -lt 10) {
        $proc = Get-CimInstance Win32_Process -Filter "ProcessId=$curPid" -EA SilentlyContinue
        if (-not $proc) { break }
        if ($proc.Name -eq 'claude.exe') { $sessionPid = $proc.ProcessId; break }
        $curPid = $proc.ParentProcessId; $depth++
    }
} catch {}

# --- Per-PID session cache ---
$sesApi = 0; $apiTotal = 0
$transcriptPath = if ($data['transcript_path']) { $data['transcript_path'] } else { "" }
$cacheDir = Join-Path $env:TEMP "ccNovaTerm-statusline-cache"
try { if (-not (Test-Path -LiteralPath $cacheDir)) { New-Item -ItemType Directory -Force -LiteralPath $cacheDir | Out-Null } } catch {}
$sessionFile = if ($sessionPid -ne 0) { Join-Path $cacheDir "ses-$sessionPid.txt" } else { Join-Path $cacheDir "ses-default.txt" }

$cApiAll = 0; $cAllLines = 0; $cAllPath = ""
$cSesPid = 0; $cApiSesBase = 0
$cLastIn = -1; $cLastOut = -1; $cLastCC = -1; $cLastCR = -1
if (Test-Path -LiteralPath $sessionFile) {
    try {
        $cl = Get-Content -LiteralPath $sessionFile -EA SilentlyContinue
        if ($cl.Count -ge 9) {
            [int]$cApiAll = $cl[0]; [int]$cAllLines = $cl[1]; $cAllPath = $cl[2]
            [int]$cSesPid = $cl[3]; [int]$cApiSesBase = $cl[4]
            [int]$cLastIn = $cl[5]; [int]$cLastOut = $cl[6]; [int]$cLastCC = $cl[7]; [int]$cLastCR = $cl[8]
        }
    } catch {}
}

# --- Inline token counting ---
$pAsst = '"type":"assistant"'
$pMsg = '"role":"assistant"'
$pIn = '"input_tokens":(\d+)'
$pOut = '"output_tokens":(\d+)'
$pCC = '"cache_creation_input_tokens":(\d+)'
$pCR = '"cache_read_input_tokens":(\d+)'

if ($transcriptPath -and (Test-Path -LiteralPath $transcriptPath)) {
    try {
        $lineCount = 0
        $sr = New-Object System.IO.StreamReader($transcriptPath, [System.Text.Encoding]::UTF8)
        while ($null -ne $sr.ReadLine()) { $lineCount++ }
        $sr.Close()

        $needFullRead = ($cAllPath -ne $transcriptPath -or $cAllLines -gt $lineCount -or $cApiAll -le 0)
        $startLine = if ($needFullRead) { 0 } else { $cAllLines }

        $lines = @()
        $sr = New-Object System.IO.StreamReader($transcriptPath, [System.Text.Encoding]::UTF8)
        $idx = 0
        while ($null -ne ($l = $sr.ReadLine())) {
            if ($idx -ge $startLine) { $lines += $l }
            $idx++
        }
        $sr.Close()

        $newApi = 0
        $prevIn = $cLastIn; $prevOut = $cLastOut; $prevCC = $cLastCC; $prevCR = $cLastCR
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $l = $lines[$i]
            if ($l -notmatch $pAsst -and $l -notmatch $pMsg) { continue }
            $ui = $l.IndexOf('"usage"'); if ($ui -lt 0) { continue }
            $us = $l.Substring($ui, [math]::Min(500, $l.Length - $ui))
            $in = 0; $out = 0; $cc = 0; $cr = 0
            if ($us -match $pIn) { $in = [int]$Matches[1] }
            if ($us -match $pOut) { $out = [int]$Matches[1] }
            if ($us -match $pCC) { $cc = [int]$Matches[1] }
            if ($us -match $pCR) { $cr = [int]$Matches[1] }

            if ($in -eq $prevIn -and $out -eq $prevOut -and $cc -eq $prevCC -and $cr -eq $prevCR) { continue }

            $newApi += $in + $out + $cc + $cr
            $prevIn = $in; $prevOut = $out; $prevCC = $cc; $prevCR = $cr
        }

        if ($needFullRead) { $apiTotal = $newApi }
        else { $apiTotal = $cApiAll + $newApi }

        if ($sessionPid -ne 0 -and $cSesPid -eq $sessionPid -and $cAllPath -eq $transcriptPath -and $cApiSesBase -gt 0 -and $apiTotal -ge $cApiSesBase) {
            $sesApi = $apiTotal - $cApiSesBase
        } else { $cApiSesBase = $apiTotal; $sesApi = 0 }

        Set-Content -LiteralPath $sessionFile "$apiTotal`n$lineCount`n$transcriptPath`n$sessionPid`n$cApiSesBase`n$prevIn`n$prevOut`n$prevCC`n$prevCR" -Force -EA SilentlyContinue
    } catch { $apiTotal = $inputTokens + $outputTokens; $sesApi = $inputTokens + $outputTokens }
} else { $apiTotal = $inputTokens + $outputTokens; $sesApi = $inputTokens + $outputTokens }

if ($sesApi -lt 0) { $sesApi = 0 }

# --- Format and display ---
function fmtW($t) { $w = $t / 10000; if ($w -ge 100) { "{0:F0}w" -f $w } elseif ($w -ge 10) { "{0:F1}w" -f $w } elseif ($w -ge 1) { "{0:F2}w" -f $w } else { "$t" } }
function esc($c) { [char]27 + "[$c" }
$B = esc "1m"; $D = esc "2m"; $R = esc "0m"; $Cy = esc "36m"; $G = esc "32m"; $Y = esc "33m"; $Rd = esc "31m"; $M = esc "35m"; $Bl = esc "34m"; $W = esc "37m"
$cc = if ($ctxPct -ge 90) { $Rd } elseif ($ctxPct -ge 70) { $Y } else { $G }
$el = if ($effort) { $e = $effort.ToLower(); if ($e -eq "max") { "${M}${B}MAX${R}" } elseif ($e -eq "xhigh") { "${Rd}${B}xhigh${R}" } elseif ($e -eq "high") { "${Y}${B}high${R}" } elseif ($e -eq "medium") { "${G}med${R}" } elseif ($e -eq "low") { "${Cy}low${R}" } else { "${D}$effort${R}" } } else { "" }
$ts = Get-Date -Format "HH:mm:ss"
Write-Host "${Cy}${B}${model}${R} ${D}|${R} ${el} ${D}|${R} ${W}ctx:${R}${cc}${B}$(fmtW $inputTokens)${R}${D}/${R}${W}${B}$(fmtW $ctxSize)${R} ${cc}${B}${ctxPct}${R}%${D}"
Write-Host "${G}${B}in:${R}${G}${B}$(fmtW $inputTokens)${R}  ${Y}${B}out:${R}${Y}${B}$(fmtW $outputTokens)${R} ${D}|${R} ${Bl}${B}ses:${R}${Bl}${B}$(fmtW $sesApi)${R} ${D}|${R} ${Rd}${B}api:${R}${Rd}${B}$(fmtW $apiTotal)${R} ${D}|${R} ${W}${B}${ts}${R}"
Write-Host "${Bl}path: ${B}${W}$(Get-Location)${R}"
