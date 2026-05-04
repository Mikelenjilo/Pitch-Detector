package com.example.pitch_detector

import android.Manifest
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import androidx.annotation.RequiresPermission
import io.flutter.plugin.common.EventChannel
import kotlin.math.max

class AudioStreamHandler: EventChannel.StreamHandler {
    private var audioRecord: AudioRecord? = null
    private var isRecording = false
    private var thread: Thread? = null

    private val mainHandler = Handler(Looper.getMainLooper())


    @RequiresPermission(Manifest.permission.RECORD_AUDIO)
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        startRecording(events)
    }


    override fun onCancel(p0: Any?) {
        stopRecording()
    }


    @RequiresPermission(Manifest.permission.RECORD_AUDIO)
    private fun startRecording(events: EventChannel.EventSink?) {
        val sampleRate = 44100
        val bufferSize = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )

        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            bufferSize,
        )

        isRecording = true
        audioRecord?.startRecording()

        thread = Thread {
            val buffer = ShortArray(bufferSize)

            while (isRecording) {
                val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0

                if (read > 0) {
                    val maxAmplitude = buffer.maxOrNull() ?: 0
                    mainHandler.post {
                        events?.success(maxAmplitude)
                    }
                }
            }
        }

        thread?.start()
    }

    private fun stopRecording() {
        isRecording = false
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
    }
}