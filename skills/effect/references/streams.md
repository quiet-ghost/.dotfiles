# Streams and Sinks

Use this for streaming data, pipelines, backpressure, and resourceful stream processing.

## Stream Mental Model

`Stream<A, E, R>` describes a stream that emits values of `A`, can fail with `E`, and requires services `R`.

Use streams when:

- Data may be large or infinite.
- Backpressure matters.
- Work should process chunks incrementally.
- A resource should stay open while data flows.
- You need composable transforms with typed failures.

Do not collect large or infinite streams just to process them as arrays.

## Creation

Common creation patterns:

- From iterable or chunk.
- From a single effect.
- From async callbacks or queues.
- From files, HTTP, or platform APIs.
- From scoped resources.

Exact constructors vary by version and platform. Inspect local examples and installed types.

## Transformation

Typical operators:

- `Stream.map`: pure transform.
- `Stream.mapEffect`: effectful transform.
- `Stream.filter`: keep matching values.
- `Stream.flatMap`: expand values to streams.
- `Stream.tap`: inspect/log without changing values.
- Chunking, grouping, throttling, and debouncing where available.

Bound concurrency for `mapEffect` or parallel transforms when input size is untrusted.

## Consumption

Common consumption patterns:

- `Stream.runCollect`: collect finite streams.
- `Stream.runDrain`: run for effects and discard values.
- `Stream.runForEach`: process each element.
- `Stream.run`: run with a `Sink`.

Only use `runCollect` when the stream is known finite and bounded.

## Sinks

`Sink` values consume stream elements and produce a result.

Use sinks for:

- Folding and aggregating.
- Writing to files or sockets.
- Parsing protocols.
- Taking a subset while preserving leftovers.
- Concurrent consumption where supported.

## Resourceful Streams

Use resourceful streams for files, sockets, cursors, and subscriptions.

Rules:

- Acquire when stream starts.
- Release when stream ends, fails, or is interrupted.
- Tie subscriptions and fibers to stream scope.
- Avoid module-level handles without finalizers.

## Error Handling

Use typed stream errors and local recovery.

Patterns:

- Recover from one stream with fallback stream.
- Map external errors into tagged errors.
- Retry source acquisition or individual element processing only when safe.
- Emit diagnostics with spans/log annotations.

## Stream Architecture

For ingestion pipelines:

1. Decode incoming items with Schema.
2. Transform typed domain values.
3. Bound concurrency for external calls.
4. Batch writes where useful.
5. Surface metrics and logs.
6. Preserve shutdown and finalization.

## Smells

- `runCollect` on unbounded streams.
- Per-element external calls with unbounded concurrency.
- Stream errors widened to `unknown` and never decoded.
- File/socket streams without scoped release.
- Business logic hidden in a giant pipeline that should be named operations.
