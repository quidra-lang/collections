# Quidra Collections

First-party general-purpose collection algorithms and data structures for Quidra 0.6.x.

## Installation

```sh
quidra install quidra-collections
```

Use the matching Quidra 0.6.x Core toolchain. Numeric-array map values require Core commit `6ade1c5dd228e3b82b27fb9c30a081d80fc00345` or later; the compatibility workflow pins that baseline. Development occurs on `develop`.

## FIFO queue

```quidra
import collections

collections.Queue<string> jobs(["first", "second"])
.jobs.push("third")
while not jobs.empty()
    string job = .jobs.take()
    print.line(job)
```

`Queue<T>` removes values in insertion order and can start with an array of values. `size()` and `empty()` query the remaining values. `.pop()` returns `T | none`, with `none` for an empty queue. `.take()` returns `T | error`, reporting `COLLECTIONS_QUEUE` when empty. Queue copies have independent value semantics. If the element type already includes the empty-queue return alternative, check `empty()` or use the other removal method when you need to distinguish a stored value from an empty queue.

## PriorityQueue

```quidra
import collections

collections.PriorityQueue<string, int> queue = collections.PriorityQueue<string, int>()
.queue.push("email", 3)
.queue.push("deploy", 1)
match .queue.pop()
    (string name, int priority)
        print.line("{name} {priority}")
    none
        print.line("empty")
```

Smaller priority values are removed first; equal priorities are removed in insertion order by default. To use a value-based tie-breaker, pass a capture-free comparator that defines a strict ordering of values. A false result in both directions preserves insertion order:

```quidra
bool by_name(string a, string b)
    return [a, b].sorted()[0] == a and a != b

func<bool>(string, string) name_order = by_name
collections.PriorityQueue<string, int> named = collections.PriorityQueue<string, int>(tie_before = name_order)
.named.push("zeta", 2)
.named.push("alpha", 2)
```

The comparator runs only on equal priorities and must be pure, transitive and consistent for the queue's lifetime. `push`, `pop`, `take`, and `clear` mutate the receiver and require Quidra's `.` marker. `peek` and `pop` return `(T, P) | none` when empty. `take` returns `(T, P) | error`, reporting `COLLECTIONS_PRIORITY_QUEUE` when empty; use it when removal is required, as in `(string name, int priority) = .queue.take()`. `size` and `empty` are read-only. Heap push/pop operations take O(log n), while `peek` is O(1).

The comparator is fixed at construction; `tie_before` cannot be reassigned after items have been inserted.

## Stable distinct values and array search

```quidra
import collections

int[] values = [7, 3, 7, 2, 3]
distinct<int> members = collections.to_distinct(values)
int[] first_occurrences = collections.unique(values)
nat position = collections.index(values, 3)
```

`to_distinct<T>(T[]) -> distinct<T>` builds a native distinct container in first-appearance order. `unique<T>(T[]) -> T[]` returns those values as an array, without sorting. Both accept the native key domain: integers, naturals, bool, string, and recursively composed tuples of these types. Empty input produces an empty result. Returned values have independent value semantics; changing a returned set or array does not change the input.

`index<T:equatable>(T[], T) -> nat | error` returns the first matching zero-based index. An absent value, including a search of an empty array, reports `COLLECTIONS_INDEX`; it does not return a numeric sentinel. Unlike distinct construction, search requires only value equality and is not restricted to hashable keys. The input remains unchanged.

These three functions also support array extension syntax after `import collections`: `values.to_distinct()`, `values.unique()`, and `values.index(3)`.

## Mutable array operations

```quidra
import collections

string[] recent = ["older"]
.recent.push("newest")
string newest = .recent.take()
.recent.insert(0, "first")
bool removed = .recent.remove("older")
```

These functions provide writable array extension syntax after importing Collections. The ordinary function form takes an explicit reference, for example `collections.push(&recent, "next")`.

| Operation | Result and behavior |
| --- | --- |
| `.values.push(value)` | Appends one value; returns `void`. |
| `.values.pop()` | Removes the last value; returns `T \| none`, with `none` for an empty array. |
| `.values.take()` | Removes the last value; returns `T \| error`, with `COLLECTIONS_EMPTY` for an empty array. |
| `.values.remove(needle)` | Removes the first equal value and returns `true`, or returns `false` without changing the array when absent. Requires `equatable` elements. |
| `.values.insert(index, value)` | Inserts before an index from zero through `len(values)`, inclusive; the final index appends. Returns `void \| error`, with `COLLECTIONS_INDEX` and no change for a larger index. |

The receiver must be a writable, runtime-sized array. Each successful operation rebinds it to a new array value using Core's ordinary append, concat and slice semantics; copies remain independent. The helpers add no resizable-storage or reference-invalidation semantics. As with `Queue`, a stored `none` cannot be distinguished from empty `pop` by its return value alone; use `take` or inspect the length when the element type includes `none`.

## Consecutive chunks

```quidra
import collections

int[] values = [1, 2, 3, 4, 5]
int[][] groups = values.chunks(2)
```

`chunks<T>(T[], nat size) -> T[][] | error` divides an array into consecutive groups of at most `size` elements. It preserves order, retains a shorter final group and returns no groups for empty input. A zero size reports `COLLECTIONS_SIZE`, including for empty input. Input and returned groups have independent value semantics. The function is also available as `collections.chunks(values, size)`.

## Grouping aligned arrays

```quidra
string[] keys = ["b", "a", "b"]
int[] values = [7, 3, 2]
auto grouped = collections.group_by(keys, values)
```

`group_by<K,V>(K[], V[]) -> map<K,V[]> | error` groups each aligned value under its key. Keys retain first-appearance order, and each group's values retain input order, including duplicates. Unequal lengths report `COLLECTIONS_LENGTH`; equal empty arrays produce an empty map. Keys follow the native map key restrictions. Neither input is mutated, and the returned groups are independent values.

## Frequencies and grouped sums

```quidra
string[] words = ["apple", "banana", "apple"]
map<string, nat> counts = collections.frequencies(words)

string[] regions = ["north", "south", "north"]
int[] amounts = [10, 5, 8]
auto totals = collections.group_sum<string, int>(regions, amounts)
```

`frequencies<T>(T[]) -> map<T,nat>` counts keys, retaining first appearance. `group_sum<K,V:integer>(K[], V[]) -> map<K,V> | error` combines aligned keys and integer values into per-key sums, preserving first key appearance. Unequal lengths report `COLLECTIONS_LENGTH`; arithmetic retains the value type's overflow checks. Only supported map key types may be used. Input arrays are never mutated.

## Consecutive runs

```quidra
auto grouped = collections.runs([1, 1, 2, 1])
```

`runs<T:equatable>(T[]) -> (T,nat)[]` groups consecutive equal values without merging non-adjacent groups. Empty input yields an empty result.

## Lexicographic array comparison

```quidra
int[] left = [1, 2]
int[] right = [1, 3]
int order = collections.lex_compare(left, right)
```

`lex_compare<T:ordered>(T[], T[]) -> int` returns -1, 0 or 1. It compares corresponding values in order, then breaks common-prefix ties by array length. It does not mutate either array.

`lex_order<T:ordered>(T[][] keys, descending=false) -> nat[]` returns indices in stable lexicographic order of variable-length key arrays. Equal keys preserve their original order; descending reverses comparisons, not equal-key order. Its current implementation uses O(n²) insertion sorting, making it appropriate for small lists rather than very large datasets.

## Map entries and sorting records

`entries<K,V>(map<K,V>) -> (K,V)[]` pairs each key with its value in map insertion order. The result has independent value semantics.

`sorted_by<T,K>(T[], const func<K>(T), descending = false) -> T[]` applies a capture-free key function once per record and returns a stable sorted copy. Equal keys keep their input order in both directions. Key types follow Core array sorting and include integers, fixed-width floating-point numbers, bool and string. Use a typed function value or explicit type arguments when calling it.

```quidra
class Result(string name, int points)

int points_of(Result result)
    return result.points

Result[] results = [Result("Aki", 5), Result("Yui", 8)]
func<int>(Result) key = points_of
auto ranked = collections.sorted_by(results, key, descending = true)
```

Use Core's `sorted(by = (...), descending = (...))` when sorting by several aligned key arrays with separate directions.

After `import collections`, `source.sorted_entries()` returns entries in
ascending key order. `source.ranked_entries()` orders them by descending
value and breaks ties by ascending key. Both require ordered keys, and
`ranked_entries()` also requires ordered values. The source remains unchanged.
An empty map produces an empty array.

## Testing

Run `bash tests/integration.sh /path/to/quidra` against the matching Core compiler.
