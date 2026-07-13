#!/bin/bash
# auto-format.sh (producer) と format-on-stop.sh (consumer) が共有する定数。
# 整形キューの置き場所を 1 箇所に集約し、片方だけ変更して読み書き先がずれ、
# 整形が無言で全停止する事故を防ぐ。両フックはこのファイルを source する。
FORMAT_QUEUE_DIR="${TMPDIR:-/tmp}/claude-format-queue"
