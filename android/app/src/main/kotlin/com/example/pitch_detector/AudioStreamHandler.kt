package com.example.pitch_detector

import android.Manifest
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import androidx.annotation.RequiresPermission
import io.flutter.plugin.common.EventChannel
import kotlin.math.*
import org.jtransforms.fft.DoubleFFT_1D

class AudioStreamHandler : EventChannel.StreamHandler {

    private var audioRecord: AudioRecord? = null
    private var isRecording = false
    private var thread: Thread? = null

    private val mainHandler = Handler(Looper.getMainLooper())

    private lateinit var window: DoubleArray
    private val freqHistory = ArrayDeque<Double>()

    @RequiresPermission(Manifest.permission.RECORD_AUDIO)
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        startRecording(events)
    }

    override fun onCancel(arguments: Any?) {
        stopRecording()
    }

    @RequiresPermission(Manifest.permission.RECORD_AUDIO)
    private fun startRecording(events: EventChannel.EventSink?) {

        val sampleRate = 44100
        val bufferSize = 4096

        window = DoubleArray(bufferSize)
        for (i in window.indices) {
            window[i] = 0.5 * (1 - cos(2.0 * Math.PI * i / (bufferSize - 1)))
        }

        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            bufferSize
        )

        isRecording = true
        audioRecord?.startRecording()

        thread = Thread {

            val buffer = ShortArray(bufferSize)

            while (isRecording) {

                val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                if (read <= 0) continue

                val doubleBuffer = DoubleArray(read)

                // 1. Convert + DC offset removal
                var mean = 0.0
                for (i in 0 until read) {
                    mean += buffer[i].toDouble()
                }
                mean /= read

                for (i in 0 until read) {
                    doubleBuffer[i] = buffer[i].toDouble() - mean
                }

                // 2. Apply window
                for (i in 0 until read) {
                    doubleBuffer[i] *= window[i]
                }

                // 3. FFT
                val fft = DoubleFFT_1D(doubleBuffer.size.toLong())
                fft.realForward(doubleBuffer)

                // 4. Magnitude computation (correct JTransforms format)
                val n = doubleBuffer.size
                val magnitudes = DoubleArray(n / 2)

                magnitudes[0] = abs(doubleBuffer[0])
                magnitudes[n / 2 - 1] = abs(doubleBuffer[1])

                for (i in 1 until n / 2 - 1) {
                    val real = doubleBuffer[2 * i]
                    val imag = doubleBuffer[2 * i + 1]
                    magnitudes[i] = sqrt(real * real + imag * imag)
                }

                // 5. Energy gate (noise filter)
                var energy = 0.0
                for (m in magnitudes) {
                    energy += m * m
                }
                energy = sqrt(energy / magnitudes.size)

                if (energy < 10000) continue

                // 6. Peak detection
                var maxIndex = 0
                var maxValue = 0.0

                for (i in 1 until magnitudes.size) {
                    if (magnitudes[i] > maxValue) {
                        maxValue = magnitudes[i]
                        maxIndex = i
                    }
                }

                // 7. Confidence check
                val total = magnitudes.sum()
                val confidence = maxValue / total
                if (confidence < 0.1) continue

                // 8. Convert to frequency
                val frequency = maxIndex * sampleRate / doubleBuffer.size.toDouble()

                if (frequency < 80 || frequency > 2000) continue

                // 9. Smoothing
                freqHistory.add(frequency)
                if (freqHistory.size > 5) freqHistory.removeFirst()

                val smoothed = freqHistory.average()

                // 10. Send to Flutter
                mainHandler.post {
                    events?.success(smoothed)
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
        thread = null
    }
}