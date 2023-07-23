package com.lat.lat_hdr_transcoder

import androidx.annotation.NonNull
import io.flutter.plugin.common.MethodChannel

enum class TranscodeErrorType(val rawValue: Int) {
    InvalidArgs(0),
    NotSupportVersion(1),
    ExistsOutputFile(2),
    FailedTranscode(3);

    val code: String
        get() = "$rawValue"

    fun message(extra: String?): String {
        return when (this) {
            InvalidArgs -> "argument are not valid"
            NotSupportVersion -> "os version is not supported: $extra"
            ExistsOutputFile -> "output file exists: $extra"
            FailedTranscode -> "failed transcode error: $extra"
        }
    }

    fun occurs(@NonNull result: MethodChannel.Result, extra: String? = null) {
        result.error(code, message(extra), null)
    }
}
