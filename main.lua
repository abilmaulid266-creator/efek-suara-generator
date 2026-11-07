require "import"
import "android.app.AlertDialog"
import "android.widget.*"
import "android.view.*"
import "android.graphics.*"
import "android.os.*"
import "java.io.*"
import "java.net.*"
import "java.lang.*"
import "java.util.ArrayList"
import "android.util.Base64"
import "android.media.MediaPlayer"
import "org.json.*"
import "android.content.Context"
import "android.content.DialogInterface"
import "android.view.WindowManager"
import "android.os.Build"
import "android.content.Intent"
import "android.net.Uri"
import "android.text.TextWatcher"

local ctx = service or activity
local handler = Handler(Looper.getMainLooper())
local mediaPlayer = MediaPlayer()
local mainDialog

-- Helper untuk Toast
local function showToast(text)
    handler.post(Runnable{
        run = function()
            Toast.makeText(ctx, tostring(text), Toast.LENGTH_SHORT).show()
        end
    })
end

-- Helper untuk mengatur tipe Window Dialog agar tidak crash di Jieshuo
local function setDialogWindowType(dlg)
    if service then
        if Build.VERSION.SDK_INT >= 22 then
            dlg.getWindow().setType(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY)
        else
            dlg.getWindow().setType(WindowManager.LayoutParams.TYPE_SYSTEM_ALERT)
        end
    end
end

-- ================== PEMBUATAN UI UTAMA ================== --

local scrollView = ScrollView(ctx)
local mainLayout = LinearLayout(ctx)
mainLayout.setOrientation(LinearLayout.VERTICAL)
mainLayout.setPadding(40, 40, 40, 40)
scrollView.addView(mainLayout)

-- Judul Ekstensi
local title = TextView(ctx)
title.setText("Efek Suara Generator")
title.setTextSize(24)
title.setTypeface(Typeface.DEFAULT_BOLD)
title.setGravity(Gravity.CENTER)
title.setPadding(0, 0, 0, 30)
mainLayout.addView(title)

-- Input Teks / Deskripsi Suara
local inputLayout = LinearLayout(ctx)
inputLayout.setOrientation(LinearLayout.VERTICAL)

-- Layout Label dan Penghitung Karakter
local labelLayout = LinearLayout(ctx)
labelLayout.setOrientation(LinearLayout.HORIZONTAL)
local inputLabel = TextView(ctx)
inputLabel.setText("Deskripsi Efek Suara:")
inputLabel.setTextSize(16)

-- Spacer agar penghitung karakter berada di kanan
local spacer = View(ctx)
spacer.setLayoutParams(LinearLayout.LayoutParams(0, 1, 1))

local charCountText = TextView(ctx)
charCountText.setText("0/500")
charCountText.setTextSize(14)
charCountText.setTextColor(Color.GRAY)

labelLayout.addView(inputLabel)
labelLayout.addView(spacer)
labelLayout.addView(charCountText)

local promptInput = EditText(ctx)
promptInput.setHint("Contoh: A futuristic laser blast with metallic echo")

inputLayout.addView(labelLayout)
inputLayout.addView(promptInput)
mainLayout.addView(inputLayout)

-- Model ID Spinner
local modelLabel = TextView(ctx)
modelLabel.setText("Model:")
modelLabel.setPadding(0, 20, 0, 0)
mainLayout.addView(modelLabel)

local modelList = ArrayList()
modelList.add("eleven_text_to_sound_v3")
modelList.add("eleven_text_to_sound_v2")
local modelAdapter = ArrayAdapter(ctx, android.R.layout.simple_spinner_item, modelList)
modelAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
local modelSpinner = Spinner(ctx)
modelSpinner.setAdapter(modelAdapter)
mainLayout.addView(modelSpinner)

-- Output Format Spinner
local formatLabel = TextView(ctx)
formatLabel.setText("Output Format:")
formatLabel.setPadding(0, 20, 0, 0)
mainLayout.addView(formatLabel)

local formatList = ArrayList()
local formats = {"mp3_44100_128", "mp3_44100_32", "mp3_44100_64", "mp3_44100_96", "mp3_44100_192", "mp3_22050_32"}
for i=1, #formats do formatList.add(formats[i]) end
local formatAdapter = ArrayAdapter(ctx, android.R.layout.simple_spinner_item, formatList)
formatAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
local formatSpinner = Spinner(ctx)
formatSpinner.setAdapter(formatAdapter)
mainLayout.addView(formatSpinner)

-- Jumlah Varians (Generations)
local variansLabel = TextView(ctx)
variansLabel.setText("Jumlah Varians (Generations):")
variansLabel.setPadding(0, 20, 0, 0)
mainLayout.addView(variansLabel)

local variansList = ArrayList()
local variansOps = {"1", "2", "3", "4"}
for i=1, #variansOps do variansList.add(variansOps[i]) end
local variansAdapter = ArrayAdapter(ctx, android.R.layout.simple_spinner_item, variansList)
variansAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
local variansSpinner = Spinner(ctx)
variansSpinner.setAdapter(variansAdapter)
mainLayout.addView(variansSpinner)

-- Prompt Influence Spinner
local influenceLabel = TextView(ctx)
influenceLabel.setText("Prompt Influence:")
influenceLabel.setPadding(0, 20, 0, 0)
mainLayout.addView(influenceLabel)

local influenceList = ArrayList()
local influences = {"Auto (Model decide)", "0.0", "0.1", "0.3", "0.5", "0.7", "0.9", "1.0"}
for i=1, #influences do influenceList.add(influences[i]) end
local influenceAdapter = ArrayAdapter(ctx, android.R.layout.simple_spinner_item, influenceList)
influenceAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
local influenceSpinner = Spinner(ctx)
influenceSpinner.setAdapter(influenceAdapter)
mainLayout.addView(influenceSpinner)

-- Duration Spinner
local durationLabel = TextView(ctx)
durationLabel.setText("Duration (Seconds):")
durationLabel.setPadding(0, 20, 0, 0)
mainLayout.addView(durationLabel)

local durationList = ArrayList()
local durations = {"Auto (Model decide)", "0.5", "1.0", "3.0", "5.0", "8.0", "15.0", "30.0"}
for i=1, #durations do durationList.add(durations[i]) end
local durationAdapter = ArrayAdapter(ctx, android.R.layout.simple_spinner_item, durationList)
durationAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
local durationSpinner = Spinner(ctx)
durationSpinner.setAdapter(durationAdapter)
mainLayout.addView(durationSpinner)

-- Loop Checkbox
local loopCheckbox = CheckBox(ctx)
loopCheckbox.setText("Loop Audio")
loopCheckbox.setChecked(false)
local loopParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
loopParams.setMargins(0, 15, 0, 0)
loopCheckbox.setLayoutParams(loopParams)
mainLayout.addView(loopCheckbox)

-- Tombol Generate
local btnGenerate = Button(ctx)
btnGenerate.setText("Generate Sound Effect")
btnGenerate.setEnabled(false) -- Mati di awal karena input kosong
local btnParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
btnParams.setMargins(0, 30, 0, 0)
btnGenerate.setLayoutParams(btnParams)
mainLayout.addView(btnGenerate)

-- Pemantau Jumlah Karakter di Input Text (Real-time)
promptInput.addTextChangedListener(TextWatcher{
    beforeTextChanged = function(s, start, count, after) end,
    onTextChanged = function(s, start, before, count)
        local textStr = tostring(s)
        local len = textStr:len()
        charCountText.setText(len .. "/500")
        
        -- Matikan tombol jika kosong atau lebih dari 500 karakter
        if len == 0 or len > 500 then
            btnGenerate.setEnabled(false)
            if len > 500 then
                charCountText.setTextColor(Color.RED)
            else
                charCountText.setTextColor(Color.GRAY)
            end
        else
            btnGenerate.setEnabled(true)
            charCountText.setTextColor(Color.GRAY)
        end
    end,
    afterTextChanged = function(s) end
})

-- Teks Pesan Error (Ditampilkan jika terjadi error API)
local errorTextView = TextView(ctx)
errorTextView.setTextColor(Color.RED)
errorTextView.setTextSize(14)
errorTextView.setPadding(0, 10, 0, 10)
errorTextView.setVisibility(View.GONE) -- Sembunyikan secara default
mainLayout.addView(errorTextView)

-- Tombol Preset (Diubah dari "Pilih Preset" menjadi "Preset")
local btnPreset = Button(ctx)
btnPreset.setText("Preset")
local btnPresetParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
btnPresetParams.setMargins(0, 15, 0, 0)
btnPreset.setLayoutParams(btnPresetParams)
mainLayout.addView(btnPreset)

-- Tempat penampungan hasil generate
local resultsLayout = LinearLayout(ctx)
resultsLayout.setOrientation(LinearLayout.VERTICAL)
mainLayout.addView(resultsLayout)

-- Tombol Tentang Developer
local btnTentang = Button(ctx)
btnTentang.setText("Tentang Developer")
local btnTentangParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
btnTentangParams.setMargins(0, 30, 0, 0)
btnTentang.setLayoutParams(btnTentangParams)
mainLayout.addView(btnTentang)

-- Tombol Keluar
local btnKeluar = Button(ctx)
btnKeluar.setText("Keluar")
mainLayout.addView(btnKeluar)


-- ================== FUNGSI DAN EVENT LISTENER ================== --

local function stopAudio()
    if mediaPlayer and mediaPlayer.isPlaying() then
        mediaPlayer.stop()
    end
    mediaPlayer.reset()
end

-- Helper Fungsi Set Spinner Value
local function setSpinnerValue(spinner, value)
    local adapter = spinner.getAdapter()
    for i=0, adapter.getCount()-1 do
        if tostring(adapter.getItem(i)) == value then
            spinner.setSelection(i)
            break
        end
    end
end

-- Helper Fungsi untuk Link
local function openLinkAndClose(urlStr, targetDialog)
    pcall(function()
        local intent = Intent(Intent.ACTION_VIEW, Uri.parse(urlStr))
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        ctx.startActivity(intent)
    end)
    stopAudio()
    if mediaPlayer then mediaPlayer.release() end
    if targetDialog then targetDialog.dismiss() end
    if mainDialog then mainDialog.dismiss() end
end

-- DIALOG PRESET
btnPreset.setOnClickListener(View.OnClickListener{
    onClick = function(v)
        local presetScrollView = ScrollView(ctx)
        local presetLayout = LinearLayout(ctx)
        presetLayout.setOrientation(LinearLayout.VERTICAL)
        presetLayout.setPadding(40, 40, 40, 40)
        presetScrollView.addView(presetLayout)

        local titlePreset = TextView(ctx)
        titlePreset.setText("Preset Efek Suara")
        titlePreset.setTextSize(22)
        titlePreset.setTypeface(Typeface.DEFAULT_BOLD)
        titlePreset.setGravity(Gravity.CENTER)
        titlePreset.setPadding(0, 0, 0, 30)
        presetLayout.addView(titlePreset)

        local presets = {
            {name = "Laser Gun Futuristic", prompt = "A futuristic laser blast with metallic echo", duration = "1.0"},
            {name = "Cinematic Impact", prompt = "A heavy cinematic bass impact with debris falling", duration = "3.0"},
            {name = "Magic Spell Cast", prompt = "A sparkling magic spell cast with a soft chime", duration = "3.0"},
            {name = "Horror Ambience", prompt = "Eerie wind blowing through a haunted forest with distant crows", duration = "15.0"},
            {name = "Digital Glitch", prompt = "Digital computer glitch and static noise", duration = "0.5"},
            {name = "Heartbeat Suspense", prompt = "Slow, heavy cinematic heartbeat pulsing", duration = "8.0"}
        }
        
        local presetDialog = AlertDialog.Builder(ctx)
            .setView(presetScrollView)
            .setCancelable(false)
            .create()

        for i=1, #presets do
            local pBtn = Button(ctx)
            pBtn.setText(presets[i].name .. "\n(Durasi: " .. presets[i].duration .. " detik)")
            pBtn.setOnClickListener(View.OnClickListener{
                onClick = function(view)
                    promptInput.setText(presets[i].prompt)
                    setSpinnerValue(durationSpinner, presets[i].duration)
                    presetDialog.dismiss()
                    showToast("Preset '" .. presets[i].name .. "' dipilih")
                end
            })
            local pParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
            pParams.setMargins(0, 0, 0, 15)
            pBtn.setLayoutParams(pParams)
            presetLayout.addView(pBtn)
        end

        local btnBackPreset = Button(ctx)
        btnBackPreset.setText("Kembali")
        local btnBackPresetParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
        btnBackPresetParams.setMargins(0, 30, 0, 0)
        btnBackPreset.setLayoutParams(btnBackPresetParams)
        presetLayout.addView(btnBackPreset)
        
        btnBackPreset.setOnClickListener(View.OnClickListener{
            onClick = function(view)
                presetDialog.dismiss()
            end
        })

        setDialogWindowType(presetDialog)
        presetDialog.show()
    end
})

-- DIALOG TENTANG DEVELOPER
btnTentang.setOnClickListener(View.OnClickListener{
    onClick = function(v)
        local aboutScrollView = ScrollView(ctx)
        local aboutLayout = LinearLayout(ctx)
        aboutLayout.setOrientation(LinearLayout.VERTICAL)
        aboutLayout.setPadding(40, 40, 40, 40)
        aboutScrollView.addView(aboutLayout)

        local titleAbout = TextView(ctx)
        titleAbout.setText("Tentang Developer")
        titleAbout.setTextSize(22)
        titleAbout.setTypeface(Typeface.DEFAULT_BOLD)
        titleAbout.setGravity(Gravity.CENTER)
        titleAbout.setPadding(0, 0, 0, 10)
        aboutLayout.addView(titleAbout)

        local devName = TextView(ctx)
        devName.setText("Developer by Abil Maulid Al-Fatah")
        devName.setTextSize(16)
        devName.setTypeface(Typeface.DEFAULT_BOLD)
        devName.setGravity(Gravity.CENTER)
        devName.setPadding(0, 0, 0, 20)
        aboutLayout.addView(devName)

        local descText = TextView(ctx)
        descText.setText("Ekstensi Efek Suara Generator ini didukung oleh teknologi AI canggih dari ElevenLabs.\n\nCara Penggunaan:\n1. Tuliskan teks deskripsi atau pilih dari Preset.\n2. Sesuaikan varians, format, dan durasi.\n3. Klik Generate dan tunggu.\n4. Putar atau download langsung ke penyimpanan internal (folder: sound effect generator).")
        descText.setTextSize(14)
        descText.setPadding(0, 0, 0, 10)
        aboutLayout.addView(descText)

        local noteText = TextView(ctx)
        noteText.setText("Catatan: Jika mau menggunakan tanpa batas, silakan instal aplikasi VPN di perangkat Anda.")
        noteText.setTextSize(14)
        noteText.setTypeface(Typeface.DEFAULT_BOLD)
        noteText.setPadding(0, 0, 0, 30)
        aboutLayout.addView(noteText)

        local aboutDialog = AlertDialog.Builder(ctx)
            .setView(aboutScrollView)
            .setCancelable(false)
            .create()

        local btnYoutube = Button(ctx)
        btnYoutube.setText("Subscribe YouTube Channel Ini")
        btnYoutube.setOnClickListener(View.OnClickListener{
            onClick = function(view)
                openLinkAndClose("https://youtube.com/@abilmaulid202?si=ymb6CRr4RCju_MLA", aboutDialog)
            end
        })
        aboutLayout.addView(btnYoutube)

        local creditLayout = LinearLayout(ctx)
        creditLayout.setOrientation(LinearLayout.VERTICAL)
        creditLayout.setPadding(0, 30, 0, 30)

        local creditText = TextView(ctx)
        creditText.setText("Kredit API by Blind teck Nexus")
        creditText.setTextSize(14)
        creditText.setGravity(Gravity.CENTER)
        creditText.setPadding(0, 0, 0, 10)
        creditLayout.addView(creditText)

        local btnTelegram = Button(ctx)
        btnTelegram.setText("Join Telegram channel Blind teck Nexus")
        btnTelegram.setOnClickListener(View.OnClickListener{
            onClick = function(view)
                openLinkAndClose("https://t.me/blindtechnexus", aboutDialog)
            end
        })
        creditLayout.addView(btnTelegram)
        aboutLayout.addView(creditLayout)

        local btnBack = Button(ctx)
        btnBack.setText("Kembali")
        btnBack.setOnClickListener(View.OnClickListener{
            onClick = function(view)
                aboutDialog.dismiss()
            end
        })
        aboutLayout.addView(btnBack)

        setDialogWindowType(aboutDialog)
        aboutDialog.show()
    end
})

-- BLOK HASIL GENERATE
local function addResultBlock(base64Data, index, total)
    local blockLayout = LinearLayout(ctx)
    blockLayout.setOrientation(LinearLayout.VERTICAL)
    blockLayout.setPadding(20, 20, 20, 20)
    
    local divider = View(ctx)
    divider.setBackgroundColor(Color.parseColor("#CCCCCC"))
    blockLayout.addView(divider, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 2))
    
    local statusText = TextView(ctx)
    if total > 1 then
        statusText.setText("✅ Efek suara varians " .. index .. " berhasil di-generate")
    else
        statusText.setText("✅ Efek suara berhasil di-generate")
    end
    statusText.setTextSize(16)
    statusText.setPadding(0, 10, 0, 10)
    blockLayout.addView(statusText)
    
    local nameInput = EditText(ctx)
    local randomNum = math.random(10000, 99999)
    nameInput.setHint("Nama file (opsional)")
    nameInput.setText("Sound Effect " .. tostring(randomNum))
    blockLayout.addView(nameInput)
    
    local actionLayout = LinearLayout(ctx)
    actionLayout.setOrientation(LinearLayout.HORIZONTAL)
    
    local btnPutar = Button(ctx)
    btnPutar.setText("Putar")
    local btnDownload = Button(ctx)
    btnDownload.setText("Download")
    
    actionLayout.addView(btnPutar)
    actionLayout.addView(btnDownload)
    blockLayout.addView(actionLayout)
    
    btnPutar.setOnClickListener(View.OnClickListener{
        onClick = function(v)
            pcall(function()
                stopAudio()
                local audioBytes = Base64.decode(base64Data, Base64.DEFAULT)
                local tempFile = File.createTempFile("temp_sfx", ".mp3", ctx.getCacheDir())
                local fos = FileOutputStream(tempFile)
                fos.write(audioBytes)
                fos.flush()
                fos.close()
                
                mediaPlayer.setDataSource(tempFile.getAbsolutePath())
                mediaPlayer.prepare()
                mediaPlayer.start()
                showToast("Memutar efek suara...")
            end)
        end
    })
    
    btnDownload.setOnClickListener(View.OnClickListener{
        onClick = function(v)
            pcall(function()
                local fileName = nameInput.getText().toString()
                if fileName == nil or fileName == "" then
                    fileName = "Sound Effect " .. tostring(math.random(10000, 99999))
                end
                if not string.match(fileName, "%.mp3$") then
                    fileName = fileName .. ".mp3"
                end
                
                local sdCard = Environment.getExternalStorageDirectory()
                local dir = File(sdCard, "sound effect generator")
                if not dir.exists() then
                    dir.mkdirs()
                end
                
                local file = File(dir, fileName)
                local audioBytes = Base64.decode(base64Data, Base64.DEFAULT)
                local fos = FileOutputStream(file)
                fos.write(audioBytes)
                fos.flush()
                fos.close()
                
                showToast("Berhasil disimpan di: " .. file.getAbsolutePath())
                -- Membacakan teks berhasil untuk screen reader
                v.announceForAccessibility("Efek suara berhasil disimpan")
            end)
        end
    })
    
    handler.post(Runnable{
        run = function()
            resultsLayout.addView(blockLayout)
        end
    })
end

-- LOGIKA API DAN TOMBOL GENERATE
btnGenerate.setOnClickListener(View.OnClickListener{
    onClick = function(v)
        local textPrompt = promptInput.getText().toString()
        if textPrompt == nil or textPrompt:len() < 1 then
            showToast("Deskripsi tidak boleh kosong!")
            return
        end
        if textPrompt:len() > 500 then
            showToast("Deskripsi maksimal 500 karakter!")
            return
        end
        
        -- Hapus hasil suara sebelumnya dari layar
        resultsLayout.removeAllViews()
        
        -- Sembunyikan dan kosongkan teks error sebelumnya (jika ada)
        errorTextView.setVisibility(View.GONE)
        errorTextView.setText("")
        
        local selectedModel = tostring(modelSpinner.getSelectedItem())
        local selectedFormat = tostring(formatSpinner.getSelectedItem())
        local selectedVarians = tonumber(tostring(variansSpinner.getSelectedItem())) 
        local selectedInfluence = tostring(influenceSpinner.getSelectedItem())
        local selectedDuration = tostring(durationSpinner.getSelectedItem())
        local isLoop = loopCheckbox.isChecked()
        
        btnGenerate.setText("Memproses... Harap tunggu")
        btnGenerate.setEnabled(false)
        
        Thread(Runnable{
            run = function()
                local success = false
                local errorMessage = "Gagal menghubungi server"
                local base64Results = {} 
                
                local status, err = pcall(function()
                    local url = URL("https://api.elevenlabs.io/sound-generation")
                    local conn = url.openConnection()
                    conn.setRequestMethod("POST")
                    conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36")
                    conn.setRequestProperty("Accept", "application/json")
                    conn.setRequestProperty("Content-Type", "application/json")
                    conn.setDoOutput(true)
                    
                    local bodyObj = JSONObject()
                    bodyObj.put("text", textPrompt)
                    bodyObj.put("model_id", selectedModel)
                    bodyObj.put("number_of_generations", selectedVarians) 
                    bodyObj.put("loop", isLoop)
                    bodyObj.put("output_format", selectedFormat)
                    
                    if selectedInfluence ~= "Auto (Model decide)" then
                        bodyObj.put("prompt_influence", tonumber(selectedInfluence))
                    end
                    
                    if selectedDuration ~= "Auto (Model decide)" then
                        bodyObj.put("duration_seconds", tonumber(selectedDuration))
                    end
                    
                    local os = conn.getOutputStream()
                    local writer = BufferedWriter(OutputStreamWriter(os, "UTF-8"))
                    writer.write(bodyObj.toString())
                    writer.flush()
                    writer.close()
                    os.close()
                    
                    local responseCode = conn.getResponseCode()
                    local is = nil
                    if responseCode >= 200 and responseCode < 400 then
                        is = conn.getInputStream()
                    else
                        is = conn.getErrorStream()
                    end
                    
                    local reader = BufferedReader(InputStreamReader(is))
                    local sb = StringBuilder()
                    local line = reader.readLine()
                    while line ~= nil do
                        sb.append(line)
                        line = reader.readLine()
                    end
                    reader.close()
                    is.close()
                    
                    local responseString = sb.toString()
                    
                    -- Parsing JSON dengan aman
                    local ok, jo = pcall(function() return JSONObject(responseString) end)
                    
                    if ok and jo then
                        if responseCode >= 200 and responseCode < 400 then
                            local arr = jo.optJSONArray("sound_generations_with_waveforms")
                            if arr and arr.length() > 0 then
                                for i = 0, arr.length() - 1 do
                                    table.insert(base64Results, arr.getJSONObject(i).getString("waveform_base_64"))
                                end
                                success = true
                            end
                        else
                            local detailStr = jo.optString("detail", "")
                            if detailStr ~= "" then
                                errorMessage = "ElevenLabs Error: " .. detailStr
                            else
                                local detailObj = jo.optJSONObject("detail")
                                if detailObj then
                                    errorMessage = "ElevenLabs Error: " .. detailObj.optString("message", "API Error")
                                else
                                    local detailArr = jo.optJSONArray("detail")
                                    if detailArr and detailArr.length() > 0 then
                                        errorMessage = "ElevenLabs Error: " .. detailArr.getJSONObject(0).optString("msg", "API Error")
                                    else
                                        errorMessage = "HTTP Error " .. responseCode
                                    end
                                end
                            end
                        end
                    else
                        errorMessage = "Invalid Response dari API (Code: " .. responseCode .. ")"
                    end
                end)
                
                handler.post(Runnable{
                    run = function()
                        -- Tombol Generate dikembalikan hanya jika input teks valid
                        local currentLen = promptInput.getText().toString():len()
                        btnGenerate.setText("Generate Sound Effect")
                        if currentLen > 0 and currentLen <= 500 then
                            btnGenerate.setEnabled(true)
                        else
                            btnGenerate.setEnabled(false)
                        end
                        
                        if not status then
                            showToast("Gagal memproses data internal sistem.")
                            errorTextView.setText("Error Sistem: Gagal memproses data.")
                            errorTextView.setVisibility(View.VISIBLE)
                        elseif success and #base64Results > 0 then
                            showToast("Berhasil generate " .. #base64Results .. " varians!")
                            
                            for i = 1, #base64Results do
                                addResultBlock(base64Results[i], i, #base64Results)
                            end
                            
                            scrollView.post(Runnable{
                                run = function()
                                    scrollView.fullScroll(View.FOCUS_DOWN)
                                end
                            })
                        else
                            showToast(errorMessage)
                            errorTextView.setText(errorMessage)
                            errorTextView.setVisibility(View.VISIBLE)
                        end
                    end
                })
            end
        }).start()
    end
})

btnKeluar.setOnClickListener(View.OnClickListener{
    onClick = function(v)
        stopAudio()
        mediaPlayer.release()
        mainDialog.dismiss()
    end
})

mainDialog = AlertDialog.Builder(ctx)
    .setView(scrollView)
    .setCancelable(false)
    .create()

setDialogWindowType(mainDialog)
mainDialog.show()Apa yang baru dari fitur teks? Kita bisa memantau karakter, misalnya kita sudah memasukkan 5 karakter, nanti akan jadi 5/500 karakter. Itu untuk maksimal karakternya, dan jika sudah melebihi batas, tombol "Generate Sound Effect" tidak bisa diklik.
 Pembaruan kedua, saya telah memperbarui ekstensi ini dari jarak jauh melalui server

require "import"
import "android.app.AlertDialog"
import "android.widget.*"
import "android.view.*"
import "android.graphics.*"
import "android.os.*"
import "java.io.*"
import "java.net.*"
import "java.lang.*"
import "java.util.ArrayList"
import "android.util.Base64"
import "android.media.MediaPlayer"
import "org.json.*"
import "android.content.Context"
import "android.content.DialogInterface"
import "android.view.WindowManager"
import "android.os.Build"
import "android.content.Intent"
import "android.net.Uri"
import "android.text.TextWatcher"

local ctx = service or activity
local handler = Handler(Looper.getMainLooper())
local mediaPlayer = MediaPlayer()
local mainDialog

-- Helper untuk Toast
local function showToast(text)
    handler.post(Runnable{
        run = function()
            Toast.makeText(ctx, tostring(text), Toast.LENGTH_SHORT).show()
        end
    })
end

-- Helper untuk mengatur tipe Window Dialog agar tidak crash di Jieshuo
local function setDialogWindowType(dlg)
    if service then
        if Build.VERSION.SDK_INT >= 22 then
            dlg.getWindow().setType(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY)
        else
            dlg.getWindow().setType(WindowManager.LayoutParams.TYPE_SYSTEM_ALERT)
        end
    end
end

-- ================== PEMBUATAN UI UTAMA ================== --

local scrollView = ScrollView(ctx)
local mainLayout = LinearLayout(ctx)
mainLayout.setOrientation(LinearLayout.VERTICAL)
mainLayout.setPadding(40, 40, 40, 40)
scrollView.addView(mainLayout)

-- Judul Ekstensi
local title = TextView(ctx)
title.setText("Efek Suara Generator")
title.setTextSize(24)
title.setTypeface(Typeface.DEFAULT_BOLD)
title.setGravity(Gravity.CENTER)
title.setPadding(0, 0, 0, 30)
mainLayout.addView(title)

-- Input Teks / Deskripsi Suara
local inputLayout = LinearLayout(ctx)
inputLayout.setOrientation(LinearLayout.VERTICAL)

-- Layout Label dan Penghitung Karakter
local labelLayout = LinearLayout(ctx)
labelLayout.setOrientation(LinearLayout.HORIZONTAL)
local inputLabel = TextView(ctx)
inputLabel.setText("Deskripsi Efek Suara:")
inputLabel.setTextSize(16)

-- Spacer agar penghitung karakter berada di kanan
local spacer = View(ctx)
spacer.setLayoutParams(LinearLayout.LayoutParams(0, 1, 1))

local charCountText = TextView(ctx)
charCountText.setText("0/500")
charCountText.setTextSize(14)
charCountText.setTextColor(Color.GRAY)

labelLayout.addView(inputLabel)
labelLayout.addView(spacer)
labelLayout.addView(charCountText)

local promptInput = EditText(ctx)
promptInput.setHint("Contoh: A futuristic laser blast with metallic echo")

inputLayout.addView(labelLayout)
inputLayout.addView(promptInput)
mainLayout.addView(inputLayout)

-- Model ID Spinner
local modelLabel = TextView(ctx)
modelLabel.setText("Model:")
modelLabel.setPadding(0, 20, 0, 0)
mainLayout.addView(modelLabel)

local modelList = ArrayList()
modelList.add("eleven_text_to_sound_v3")
modelList.add("eleven_text_to_sound_v2")
local modelAdapter = ArrayAdapter(ctx, android.R.layout.simple_spinner_item, modelList)
modelAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
local modelSpinner = Spinner(ctx)
modelSpinner.setAdapter(modelAdapter)
mainLayout.addView(modelSpinner)

-- Output Format Spinner
local formatLabel = TextView(ctx)
formatLabel.setText("Output Format:")
formatLabel.setPadding(0, 20, 0, 0)
mainLayout.addView(formatLabel)

local formatList = ArrayList()
local formats = {"mp3_44100_128", "mp3_44100_32", "mp3_44100_64", "mp3_44100_96", "mp3_44100_192", "mp3_22050_32"}
for i=1, #formats do formatList.add(formats[i]) end
local formatAdapter = ArrayAdapter(ctx, android.R.layout.simple_spinner_item, formatList)
formatAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
local formatSpinner = Spinner(ctx)
formatSpinner.setAdapter(formatAdapter)
mainLayout.addView(formatSpinner)

-- Jumlah Varians (Generations)
local variansLabel = TextView(ctx)
variansLabel.setText("Jumlah Varians (Generations):")
variansLabel.setPadding(0, 20, 0, 0)
mainLayout.addView(variansLabel)

local variansList = ArrayList()
local variansOps = {"1", "2", "3", "4"}
for i=1, #variansOps do variansList.add(variansOps[i]) end
local variansAdapter = ArrayAdapter(ctx, android.R.layout.simple_spinner_item, variansList)
variansAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
local variansSpinner = Spinner(ctx)
variansSpinner.setAdapter(variansAdapter)
mainLayout.addView(variansSpinner)

-- Prompt Influence Spinner
local influenceLabel = TextView(ctx)
influenceLabel.setText("Prompt Influence:")
influenceLabel.setPadding(0, 20, 0, 0)
mainLayout.addView(influenceLabel)

local influenceList = ArrayList()
local influences = {"Auto (Model decide)", "0.0", "0.1", "0.3", "0.5", "0.7", "0.9", "1.0"}
for i=1, #influences do influenceList.add(influences[i]) end
local influenceAdapter = ArrayAdapter(ctx, android.R.layout.simple_spinner_item, influenceList)
influenceAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
local influenceSpinner = Spinner(ctx)
influenceSpinner.setAdapter(influenceAdapter)
mainLayout.addView(influenceSpinner)

-- Duration Spinner
local durationLabel = TextView(ctx)
durationLabel.setText("Duration (Seconds):")
durationLabel.setPadding(0, 20, 0, 0)
mainLayout.addView(durationLabel)

local durationList = ArrayList()
local durations = {"Auto (Model decide)", "0.5", "1.0", "3.0", "5.0", "8.0", "15.0", "30.0"}
for i=1, #durations do durationList.add(durations[i]) end
local durationAdapter = ArrayAdapter(ctx, android.R.layout.simple_spinner_item, durationList)
durationAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
local durationSpinner = Spinner(ctx)
durationSpinner.setAdapter(durationAdapter)
mainLayout.addView(durationSpinner)

-- Loop Checkbox
local loopCheckbox = CheckBox(ctx)
loopCheckbox.setText("Loop Audio")
loopCheckbox.setChecked(false)
local loopParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
loopParams.setMargins(0, 15, 0, 0)
loopCheckbox.setLayoutParams(loopParams)
mainLayout.addView(loopCheckbox)

-- Tombol Generate
local btnGenerate = Button(ctx)
btnGenerate.setText("Generate Sound Effect")
btnGenerate.setEnabled(false) -- Mati di awal karena input kosong
local btnParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
btnParams.setMargins(0, 30, 0, 0)
btnGenerate.setLayoutParams(btnParams)
mainLayout.addView(btnGenerate)

-- Pemantau Jumlah Karakter di Input Text (Real-time)
promptInput.addTextChangedListener(TextWatcher{
    beforeTextChanged = function(s, start, count, after) end,
    onTextChanged = function(s, start, before, count)
        local textStr = tostring(s)
        local len = textStr:len()
        charCountText.setText(len .. "/500")
        
        -- Matikan tombol jika kosong atau lebih dari 500 karakter
        if len == 0 or len > 500 then
            btnGenerate.setEnabled(false)
            if len > 500 then
                charCountText.setTextColor(Color.RED)
            else
                charCountText.setTextColor(Color.GRAY)
            end
        else
            btnGenerate.setEnabled(true)
            charCountText.setTextColor(Color.GRAY)
        end
    end,
    afterTextChanged = function(s) end
})

-- Teks Pesan Error (Ditampilkan jika terjadi error API)
local errorTextView = TextView(ctx)
errorTextView.setTextColor(Color.RED)
errorTextView.setTextSize(14)
errorTextView.setPadding(0, 10, 0, 10)
errorTextView.setVisibility(View.GONE) -- Sembunyikan secara default
mainLayout.addView(errorTextView)

-- Tombol Preset (Diubah dari "Pilih Preset" menjadi "Preset")
local btnPreset = Button(ctx)
btnPreset.setText("Preset")
local btnPresetParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
btnPresetParams.setMargins(0, 15, 0, 0)
btnPreset.setLayoutParams(btnPresetParams)
mainLayout.addView(btnPreset)

-- Tempat penampungan hasil generate
local resultsLayout = LinearLayout(ctx)
resultsLayout.setOrientation(LinearLayout.VERTICAL)
mainLayout.addView(resultsLayout)

-- Tombol Tentang Developer
local btnTentang = Button(ctx)
btnTentang.setText("Tentang Developer")
local btnTentangParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
btnTentangParams.setMargins(0, 30, 0, 0)
btnTentang.setLayoutParams(btnTentangParams)
mainLayout.addView(btnTentang)

-- Tombol Keluar
local btnKeluar = Button(ctx)
btnKeluar.setText("Keluar")
mainLayout.addView(btnKeluar)


-- ================== FUNGSI DAN EVENT LISTENER ================== --

local function stopAudio()
    if mediaPlayer and mediaPlayer.isPlaying() then
        mediaPlayer.stop()
    end
    mediaPlayer.reset()
end

-- Helper Fungsi Set Spinner Value
local function setSpinnerValue(spinner, value)
    local adapter = spinner.getAdapter()
    for i=0, adapter.getCount()-1 do
        if tostring(adapter.getItem(i)) == value then
            spinner.setSelection(i)
            break
        end
    end
end

-- Helper Fungsi untuk Link
local function openLinkAndClose(urlStr, targetDialog)
    pcall(function()
        local intent = Intent(Intent.ACTION_VIEW, Uri.parse(urlStr))
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        ctx.startActivity(intent)
    end)
    stopAudio()
    if mediaPlayer then mediaPlayer.release() end
    if targetDialog then targetDialog.dismiss() end
    if mainDialog then mainDialog.dismiss() end
end

-- DIALOG PRESET
btnPreset.setOnClickListener(View.OnClickListener{
    onClick = function(v)
        local presetScrollView = ScrollView(ctx)
        local presetLayout = LinearLayout(ctx)
        presetLayout.setOrientation(LinearLayout.VERTICAL)
        presetLayout.setPadding(40, 40, 40, 40)
        presetScrollView.addView(presetLayout)

        local titlePreset = TextView(ctx)
        titlePreset.setText("Preset Efek Suara")
        titlePreset.setTextSize(22)
        titlePreset.setTypeface(Typeface.DEFAULT_BOLD)
        titlePreset.setGravity(Gravity.CENTER)
        titlePreset.setPadding(0, 0, 0, 30)
        presetLayout.addView(titlePreset)

        local presets = {
            {name = "Laser Gun Futuristic", prompt = "A futuristic laser blast with metallic echo", duration = "1.0"},
            {name = "Cinematic Impact", prompt = "A heavy cinematic bass impact with debris falling", duration = "3.0"},
            {name = "Magic Spell Cast", prompt = "A sparkling magic spell cast with a soft chime", duration = "3.0"},
            {name = "Horror Ambience", prompt = "Eerie wind blowing through a haunted forest with distant crows", duration = "15.0"},
            {name = "Digital Glitch", prompt = "Digital computer glitch and static noise", duration = "0.5"},
            {name = "Heartbeat Suspense", prompt = "Slow, heavy cinematic heartbeat pulsing", duration = "8.0"}
        }
        
        local presetDialog = AlertDialog.Builder(ctx)
            .setView(presetScrollView)
            .setCancelable(false)
            .create()

        for i=1, #presets do
            local pBtn = Button(ctx)
            pBtn.setText(presets[i].name .. "\n(Durasi: " .. presets[i].duration .. " detik)")
            pBtn.setOnClickListener(View.OnClickListener{
                onClick = function(view)
                    promptInput.setText(presets[i].prompt)
                    setSpinnerValue(durationSpinner, presets[i].duration)
                    presetDialog.dismiss()
                    showToast("Preset '" .. presets[i].name .. "' dipilih")
                end
            })
            local pParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
            pParams.setMargins(0, 0, 0, 15)
            pBtn.setLayoutParams(pParams)
            presetLayout.addView(pBtn)
        end

        local btnBackPreset = Button(ctx)
        btnBackPreset.setText("Kembali")
        local btnBackPresetParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
        btnBackPresetParams.setMargins(0, 30, 0, 0)
        btnBackPreset.setLayoutParams(btnBackPresetParams)
        presetLayout.addView(btnBackPreset)
        
        btnBackPreset.setOnClickListener(View.OnClickListener{
            onClick = function(view)
                presetDialog.dismiss()
            end
        })

        setDialogWindowType(presetDialog)
        presetDialog.show()
    end
})

-- DIALOG TENTANG DEVELOPER
btnTentang.setOnClickListener(View.OnClickListener{
    onClick = function(v)
        local aboutScrollView = ScrollView(ctx)
        local aboutLayout = LinearLayout(ctx)
        aboutLayout.setOrientation(LinearLayout.VERTICAL)
        aboutLayout.setPadding(40, 40, 40, 40)
        aboutScrollView.addView(aboutLayout)

        local titleAbout = TextView(ctx)
        titleAbout.setText("Tentang Developer")
        titleAbout.setTextSize(22)
        titleAbout.setTypeface(Typeface.DEFAULT_BOLD)
        titleAbout.setGravity(Gravity.CENTER)
        titleAbout.setPadding(0, 0, 0, 10)
        aboutLayout.addView(titleAbout)

        local devName = TextView(ctx)
        devName.setText("Developer by Abil Maulid Al-Fatah")
        devName.setTextSize(16)
        devName.setTypeface(Typeface.DEFAULT_BOLD)
        devName.setGravity(Gravity.CENTER)
        devName.setPadding(0, 0, 0, 20)
        aboutLayout.addView(devName)

        local descText = TextView(ctx)
        descText.setText("Ekstensi Efek Suara Generator ini didukung oleh teknologi AI canggih dari ElevenLabs.\n\nCara Penggunaan:\n1. Tuliskan teks deskripsi atau pilih dari Preset.\n2. Sesuaikan varians, format, dan durasi.\n3. Klik Generate dan tunggu.\n4. Putar atau download langsung ke penyimpanan internal (folder: sound effect generator).")
        descText.setTextSize(14)
        descText.setPadding(0, 0, 0, 10)
        aboutLayout.addView(descText)

        local noteText = TextView(ctx)
        noteText.setText("Catatan: Jika mau menggunakan tanpa batas, silakan instal aplikasi VPN di perangkat Anda.")
        noteText.setTextSize(14)
        noteText.setTypeface(Typeface.DEFAULT_BOLD)
        noteText.setPadding(0, 0, 0, 30)
        aboutLayout.addView(noteText)

        local aboutDialog = AlertDialog.Builder(ctx)
            .setView(aboutScrollView)
            .setCancelable(false)
            .create()

        local btnYoutube = Button(ctx)
        btnYoutube.setText("Subscribe YouTube Channel Ini")
        btnYoutube.setOnClickListener(View.OnClickListener{
            onClick = function(view)
                openLinkAndClose("https://youtube.com/@abilmaulid202?si=ymb6CRr4RCju_MLA", aboutDialog)
            end
        })
        aboutLayout.addView(btnYoutube)

        local creditLayout = LinearLayout(ctx)
        creditLayout.setOrientation(LinearLayout.VERTICAL)
        creditLayout.setPadding(0, 30, 0, 30)

        local creditText = TextView(ctx)
        creditText.setText("Kredit API by Blind teck Nexus")
        creditText.setTextSize(14)
        creditText.setGravity(Gravity.CENTER)
        creditText.setPadding(0, 0, 0, 10)
        creditLayout.addView(creditText)

        local btnTelegram = Button(ctx)
        btnTelegram.setText("Join Telegram channel Blind teck Nexus")
        btnTelegram.setOnClickListener(View.OnClickListener{
            onClick = function(view)
                openLinkAndClose("https://t.me/blindtechnexus", aboutDialog)
            end
        })
        creditLayout.addView(btnTelegram)
        aboutLayout.addView(creditLayout)

        local btnBack = Button(ctx)
        btnBack.setText("Kembali")
        btnBack.setOnClickListener(View.OnClickListener{
            onClick = function(view)
                aboutDialog.dismiss()
            end
        })
        aboutLayout.addView(btnBack)

        setDialogWindowType(aboutDialog)
        aboutDialog.show()
    end
})

-- BLOK HASIL GENERATE
local function addResultBlock(base64Data, index, total)
    local blockLayout = LinearLayout(ctx)
    blockLayout.setOrientation(LinearLayout.VERTICAL)
    blockLayout.setPadding(20, 20, 20, 20)
    
    local divider = View(ctx)
    divider.setBackgroundColor(Color.parseColor("#CCCCCC"))
    blockLayout.addView(divider, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 2))
    
    local statusText = TextView(ctx)
    if total > 1 then
        statusText.setText("✅ Efek suara varians " .. index .. " berhasil di-generate")
    else
        statusText.setText("✅ Efek suara berhasil di-generate")
    end
    statusText.setTextSize(16)
    statusText.setPadding(0, 10, 0, 10)
    blockLayout.addView(statusText)
    
    local nameInput = EditText(ctx)
    local randomNum = math.random(10000, 99999)
    nameInput.setHint("Nama file (opsional)")
    nameInput.setText("Sound Effect " .. tostring(randomNum))
    blockLayout.addView(nameInput)
    
    local actionLayout = LinearLayout(ctx)
    actionLayout.setOrientation(LinearLayout.HORIZONTAL)
    
    local btnPutar = Button(ctx)
    btnPutar.setText("Putar")
    local btnDownload = Button(ctx)
    btnDownload.setText("Download")
    
    actionLayout.addView(btnPutar)
    actionLayout.addView(btnDownload)
    blockLayout.addView(actionLayout)
    
    btnPutar.setOnClickListener(View.OnClickListener{
        onClick = function(v)
            pcall(function()
                stopAudio()
                local audioBytes = Base64.decode(base64Data, Base64.DEFAULT)
                local tempFile = File.createTempFile("temp_sfx", ".mp3", ctx.getCacheDir())
                local fos = FileOutputStream(tempFile)
                fos.write(audioBytes)
                fos.flush()
                fos.close()
                
                mediaPlayer.setDataSource(tempFile.getAbsolutePath())
                mediaPlayer.prepare()
                mediaPlayer.start()
                showToast("Memutar efek suara...")
            end)
        end
    })
    
    btnDownload.setOnClickListener(View.OnClickListener{
        onClick = function(v)
            pcall(function()
                local fileName = nameInput.getText().toString()
                if fileName == nil or fileName == "" then
                    fileName = "Sound Effect " .. tostring(math.random(10000, 99999))
                end
                if not string.match(fileName, "%.mp3$") then
                    fileName = fileName .. ".mp3"
                end
                
                local sdCard = Environment.getExternalStorageDirectory()
                local dir = File(sdCard, "sound effect generator")
                if not dir.exists() then
                    dir.mkdirs()
                end
                
                local file = File(dir, fileName)
                local audioBytes = Base64.decode(base64Data, Base64.DEFAULT)
                local fos = FileOutputStream(file)
                fos.write(audioBytes)
                fos.flush()
                fos.close()
                
                showToast("Berhasil disimpan di: " .. file.getAbsolutePath())
                -- Membacakan teks berhasil untuk screen reader
                v.announceForAccessibility("Efek suara berhasil disimpan")
            end)
        end
    })
    
    handler.post(Runnable{
        run = function()
            resultsLayout.addView(blockLayout)
        end
    })
end

-- LOGIKA API DAN TOMBOL GENERATE
btnGenerate.setOnClickListener(View.OnClickListener{
    onClick = function(v)
        local textPrompt = promptInput.getText().toString()
        if textPrompt == nil or textPrompt:len() < 1 then
            showToast("Deskripsi tidak boleh kosong!")
            return
        end
        if textPrompt:len() > 500 then
            showToast("Deskripsi maksimal 500 karakter!")
            return
        end
        
        -- Hapus hasil suara sebelumnya dari layar
        resultsLayout.removeAllViews()
        
        -- Sembunyikan dan kosongkan teks error sebelumnya (jika ada)
        errorTextView.setVisibility(View.GONE)
        errorTextView.setText("")
        
        local selectedModel = tostring(modelSpinner.getSelectedItem())
        local selectedFormat = tostring(formatSpinner.getSelectedItem())
        local selectedVarians = tonumber(tostring(variansSpinner.getSelectedItem())) 
        local selectedInfluence = tostring(influenceSpinner.getSelectedItem())
        local selectedDuration = tostring(durationSpinner.getSelectedItem())
        local isLoop = loopCheckbox.isChecked()
        
        btnGenerate.setText("Memproses... Harap tunggu")
        btnGenerate.setEnabled(false)
        
        Thread(Runnable{
            run = function()
                local success = false
                local errorMessage = "Gagal menghubungi server"
                local base64Results = {} 
                
                local status, err = pcall(function()
                    local url = URL("https://api.elevenlabs.io/sound-generation")
                    local conn = url.openConnection()
                    conn.setRequestMethod("POST")
                    conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36")
                    conn.setRequestProperty("Accept", "application/json")
                    conn.setRequestProperty("Content-Type", "application/json")
                    conn.setDoOutput(true)
                    
                    local bodyObj = JSONObject()
                    bodyObj.put("text", textPrompt)
                    bodyObj.put("model_id", selectedModel)
                    bodyObj.put("number_of_generations", selectedVarians) 
                    bodyObj.put("loop", isLoop)
                    bodyObj.put("output_format", selectedFormat)
                    
                    if selectedInfluence ~= "Auto (Model decide)" then
                        bodyObj.put("prompt_influence", tonumber(selectedInfluence))
                    end
                    
                    if selectedDuration ~= "Auto (Model decide)" then
                        bodyObj.put("duration_seconds", tonumber(selectedDuration))
                    end
                    
                    local os = conn.getOutputStream()
                    local writer = BufferedWriter(OutputStreamWriter(os, "UTF-8"))
                    writer.write(bodyObj.toString())
                    writer.flush()
                    writer.close()
                    os.close()
                    
                    local responseCode = conn.getResponseCode()
                    local is = nil
                    if responseCode >= 200 and responseCode < 400 then
                        is = conn.getInputStream()
                    else
                        is = conn.getErrorStream()
                    end
                    
                    local reader = BufferedReader(InputStreamReader(is))
                    local sb = StringBuilder()
                    local line = reader.readLine()
                    while line ~= nil do
                        sb.append(line)
                        line = reader.readLine()
                    end
                    reader.close()
                    is.close()
                    
                    local responseString = sb.toString()
                    
                    -- Parsing JSON dengan aman
                    local ok, jo = pcall(function() return JSONObject(responseString) end)
                    
                    if ok and jo then
                        if responseCode >= 200 and responseCode < 400 then
                            local arr = jo.optJSONArray("sound_generations_with_waveforms")
                            if arr and arr.length() > 0 then
                                for i = 0, arr.length() - 1 do
                                    table.insert(base64Results, arr.getJSONObject(i).getString("waveform_base_64"))
                                end
                                success = true
                            end
                        else
                            local detailStr = jo.optString("detail", "")
                            if detailStr ~= "" then
                                errorMessage = "ElevenLabs Error: " .. detailStr
                            else
                                local detailObj = jo.optJSONObject("detail")
                                if detailObj then
                                    errorMessage = "ElevenLabs Error: " .. detailObj.optString("message", "API Error")
                                else
                                    local detailArr = jo.optJSONArray("detail")
                                    if detailArr and detailArr.length() > 0 then
                                        errorMessage = "ElevenLabs Error: " .. detailArr.getJSONObject(0).optString("msg", "API Error")
                                    else
                                        errorMessage = "HTTP Error " .. responseCode
                                    end
                                end
                            end
                        end
                    else
                        errorMessage = "Invalid Response dari API (Code: " .. responseCode .. ")"
                    end
                end)
                
                handler.post(Runnable{
                    run = function()
                        -- Tombol Generate dikembalikan hanya jika input teks valid
                        local currentLen = promptInput.getText().toString():len()
                        btnGenerate.setText("Generate Sound Effect")
                        if currentLen > 0 and currentLen <= 500 then
                            btnGenerate.setEnabled(true)
                        else
                            btnGenerate.setEnabled(false)
                        end
                        
                        if not status then
                            showToast("Gagal memproses data internal sistem.")
                            errorTextView.setText("Error Sistem: Gagal memproses data.")
                            errorTextView.setVisibility(View.VISIBLE)
                        elseif success and #base64Results > 0 then
                            showToast("Berhasil generate " .. #base64Results .. " varians!")
                            
                            for i = 1, #base64Results do
                                addResultBlock(base64Results[i], i, #base64Results)
                            end
                            
                            scrollView.post(Runnable{
                                run = function()
                                    scrollView.fullScroll(View.FOCUS_DOWN)
                                end
                            })
                        else
                            showToast(errorMessage)
                            errorTextView.setText(errorMessage)
                            errorTextView.setVisibility(View.VISIBLE)
                        end
                    end
                })
            end
        }).start()
    end
})

btnKeluar.setOnClickListener(View.OnClickListener{
    onClick = function(v)
        stopAudio()
        mediaPlayer.release()
        mainDialog.dismiss()
    end
})

mainDialog = AlertDialog.Builder(ctx)
    .setView(scrollView)
    .setCancelable(false)
    .create()

setDialogWindowType(mainDialog)
mainDialog.show()