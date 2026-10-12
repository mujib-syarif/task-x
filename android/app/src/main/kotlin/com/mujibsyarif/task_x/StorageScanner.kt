package com.mujibsyarif.task_x

import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.DocumentsContract
import java.util.PriorityQueue

private val CATEGORY_NAMES = listOf("Gambar", "Video", "Audio", "Dokumen", "Aplikasi (APK)", "Arsip", "Lainnya")

private fun categoryOf(mime: String): Int = when {
    mime.startsWith("image/") -> 0
    mime.startsWith("video/") -> 1
    mime.startsWith("audio/") -> 2
    mime == "application/pdf" || mime.startsWith("text/") || mime.contains("officedocument") ||
        mime == "application/msword" -> 3
    mime == "application/vnd.android.package-archive" -> 4
    mime == "application/zip" || mime.contains("compressed") || mime.contains("x-tar") ||
        mime.contains("x-rar") || mime.contains("7z") -> 5
    else -> 6
}

/**
 * Memindai folder yang dipilih pengguna lewat Storage Access Framework.
 * Tidak memerlukan izin akses semua file dan tidak pernah menghapus apa pun.
 */
class StorageScanner(private val ctx: Context) {

    private class Entry(val name: String, val size: Long, val mime: String, val uri: String)

    private fun query(uri: Uri, projection: Array<String>): Cursor? = try {
        ctx.contentResolver.query(uri, projection, null, null, null)
    } catch (e: Exception) {
        null
    }

    fun scan(treeUriStr: String, topN: Int, maxFiles: Int): Map<String, Any?> {
        val treeUri = Uri.parse(treeUriStr)
        val rootId = DocumentsContract.getTreeDocumentId(treeUri)
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
        )
        val stack = ArrayList<String>()
        stack.add(rootId)
        val catBytes = LongArray(CATEGORY_NAMES.size)
        val catCount = LongArray(CATEGORY_NAMES.size)
        val heap = PriorityQueue<Entry>(11, Comparator<Entry> { a, b -> a.size.compareTo(b.size) })
        var files = 0L
        var total = 0L
        var truncated = false

        while (stack.isNotEmpty() && !truncated) {
            val dirId = stack.removeAt(stack.size - 1)
            val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, dirId)
            val cursor = query(childrenUri, projection)
            if (cursor == null) continue
            try {
                while (cursor.moveToNext()) {
                    val id = cursor.getString(0) ?: continue
                    val name = cursor.getString(1) ?: ""
                    val mime = cursor.getString(2) ?: ""
                    val size = if (cursor.isNull(3)) 0L else cursor.getLong(3)
                    if (mime == DocumentsContract.Document.MIME_TYPE_DIR) {
                        stack.add(id)
                        continue
                    }
                    files++
                    total += size
                    val cat = categoryOf(mime)
                    catBytes[cat] += size
                    catCount[cat] += 1
                    if (heap.size < topN || (heap.peek() != null && size > heap.peek()!!.size)) {
                        val docUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, id).toString()
                        heap.add(Entry(name, size, mime, docUri))
                        if (heap.size > topN) heap.poll()
                    }
                    if (files >= maxFiles) {
                        truncated = true
                        break
                    }
                }
            } finally {
                cursor.close()
            }
        }

        val categories = ArrayList<Map<String, Any?>>()
        for (i in CATEGORY_NAMES.indices) {
            val m = HashMap<String, Any?>()
            m["name"] = CATEGORY_NAMES[i]
            m["bytes"] = catBytes[i]
            m["count"] = catCount[i]
            categories.add(m)
        }
        val top = ArrayList<Entry>(heap)
        top.sortByDescending { it.size }
        val topList = ArrayList<Map<String, Any?>>()
        for (e in top) {
            val m = HashMap<String, Any?>()
            m["name"] = e.name
            m["size"] = e.size
            m["mime"] = e.mime
            m["uri"] = e.uri
            topList.add(m)
        }
        val result = HashMap<String, Any?>()
        result["totalBytes"] = total
        result["fileCount"] = files
        result["truncated"] = truncated
        result["categories"] = categories
        result["files"] = topList
        return result
    }
}
