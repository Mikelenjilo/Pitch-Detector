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
import kotlin.math.cos
import kotlin.math.max
import org.jtransforms.fft.DoubleFFT_1D
import kotlin.math.sqrt

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
                    val doubleBuffer = DoubleArray(read)
                    for (i in 0 until read) {
                        doubleBuffer[i] = buffer[i].toDouble()
                    }

                    for (i in doubleBuffer.indices) {
                        doubleBuffer[i] *= (0.5 * (1 - cos(2 * Math.PI * i / (doubleBuffer.size - 1))))
                    }

                    val fft = org.jtransforms.fft.DoubleFFT_1D(doubleBuffer.size.toLong())
                    fft.realForward(doubleBuffer)

                    // Compute magnitude
                    val magnitudes = DoubleArray(doubleBuffer.size / 2)

                    for (i in magnitudes.indices) {
                        val real = doubleBuffer[2 * i]
                        val imag = doubleBuffer[2 * i + 1]
                        magnitudes[i] = sqrt(real * real + imag * imag)
                    }

                    // Find peak
                    var maxIndex = 0
                    var maxValue = Double.MIN_VALUE

                    for (i in magnitudes.indices) {
                        if (magnitudes[i] > maxValue) {
                            maxValue = magnitudes[i]
                            maxIndex = i
                        }
                    }

                    // Convert to frequency
                    val frequency = maxIndex * sampleRate / doubleBuffer.size.toDouble()

                    mainHandler.post {
                        events?.success(frequency)
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