#!/usr/bin/env bash
set -euo pipefail
QUIDRA="${1:?usage: integration.sh /path/to/quidra}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP"
export QUIDRA_CACHE_DIR="$TMP/cache"
"$QUIDRA" package validate "$ROOT"
"$QUIDRA" install "$ROOT"
"$QUIDRA" run "$ROOT/tests/smoke.qui" > "$TMP/output"
printf 'apple=2\nsize=3\ndeploy:1\nbackup:1\nemail:3\nempty=true\neast=10\nlength-error\nruns=3:a:2\nlex=-1\nlex-equal=0\nlex-prefix=-1\nnamed=beta:1\nnamed=apple:2\nnamed=zebra:2\nrank=1:2:0\n' > "$TMP/expected"
diff -u "$TMP/expected" "$TMP/output"

"$QUIDRA" run "$ROOT/tests/utilities.qui" > "$TMP/utilities-output"
cat > "$TMP/utilities-expected" <<'EXPECTED'
unique=7:3:2
empty=0
index=1
missing=COLLECTIONS_INDEX
empty-index=COLLECTIONS_INDEX
keys=b|a
group=7:7:3
empty-groups=0
length=COLLECTIONS_LENGTH
unchanged=5:7:3
distinct=7:3:2
empty-distinct=0
independent=5:7:4
words=first|second
first-index=0
extensions=3:3:3
float-index=0
extra-values=COLLECTIONS_LENGTH
tuple=2:x|z
group-independent=7
queue-empty=true
queue-first=first
queue-next=second
queue-next=third
queue-copy-size=2
scored=second:first:third
entry=second:3
entry=first:1
queue-drained=COLLECTIONS_QUEUE
queue-seeded=7:9
queue-union=union
sorted=a:3
sorted=b:1
sorted=z:3
ranked=a:3
ranked=z:3
ranked=b:1
empty-ranked=0
sorted-group=a:first
sorted-group=z:last
EXPECTED
diff -u "$TMP/utilities-expected" "$TMP/utilities-output"

"$QUIDRA" run "$ROOT/tests/array_mutation.qui" > "$TMP/array-mutation-output"
cat > "$TMP/array-mutation-expected" <<'EXPECTED'
push=4:3:3
remove=true:2:3
remove-missing=false:3
insert=7:9:8
take=8:5
pop=3:4
copy=1:2:1
insert-error=COLLECTIONS_INDEX:4:7:9
remove-last=true:3
remove-middle=true:9
remove-single=true:0
remove-empty=false
empty-pop=none
empty-take=COLLECTIONS_EMPTY
insert-empty=5:0
pop-single=6:0
tuple-remove=true
tuple-take=b:2
class-take=7
priority-take=first:1
priority-take=second:1
priority-take=later:3
priority-copy=3
priority-empty=COLLECTIONS_PRIORITY_QUEUE
EXPECTED
diff -u "$TMP/array-mutation-expected" "$TMP/array-mutation-output"

"$QUIDRA" run "$ROOT/tests/chunks.qui" > "$TMP/chunks-output"
cat > "$TMP/chunks-expected" <<'EXPECTED'
partial=3:2:1:5
exact=2:4
wide=1:5
huge=1:5
empty=0
independent=1:5
zero=COLLECTIONS_SIZE
tuple=x:3
EXPECTED
diff -u "$TMP/chunks-expected" "$TMP/chunks-output"

cat > "$TMP/mutate-comparator.qui" <<'QUI'
import collections
auto queue = collections.PriorityQueue<string, int>()
.queue.push("item", 1)
queue.tie_before = none
QUI
if "$QUIDRA" check "$TMP/mutate-comparator.qui" > "$TMP/immutable-error" 2>&1; then
    echo "PriorityQueue comparator unexpectedly writable" >&2
    exit 1
fi
grep -Eqi 'const|read.only|immutable' "$TMP/immutable-error"


"$QUIDRA" run "$ROOT/tests/argmin.qui" > "$TMP/argmin-output"
cat > "$TMP/argmin-expected" <<'EXPECTED'
first-tie=2
masked=1
all-false=none
empty=none
mismatch=COLLECTIONS_LENGTH
unsigned=1
EXPECTED
diff -u "$TMP/argmin-expected" "$TMP/argmin-output"

"$QUIDRA" run "$ROOT/tests/graph_and_tree.qui" > "$TMP/graph-and-tree-output"
cat > "$TMP/graph-and-tree-expected" <<'EXPECTED'
true
true
COLLECTIONS_VERTEX
fourth:first:third:second
5:8:7
COLLECTIONS_NODE
true
true
true
true
2:0
7
EXPECTED
diff -u "$TMP/graph-and-tree-expected" "$TMP/graph-and-tree-output"
