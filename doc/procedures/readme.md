
# procedures

## core

* [_skip](_skip.md) - Skips x messages, mostly used for testing flor.
* [apply](apply.md) - Applies a function.
* [break, continue](break.md) - Breaks or continues a "while" or "until".
* [case](case.md) - The classical case form.
* [cond](cond.md) - Evaluates all its condition children until one evaluates to true (or it's an else), then executes the corresponding clause child.
* [cursor](cursor.md) - Executes child expressions in sequence, but may be "guided".
* [def, fun, define](define.md) - Defines a function.
* [do-return](do_return.md) - Takes a set of arguments and returns a function that will return those arguments again.
* [fail, error](fail.md) - Explicitely raises an error.
* [if, unless, ife, unlesse](if.md) - The classical "if" (and its "unless" sidequick)
* [loop](loop.md) - Executes child expressions in sequence, then loops around.
* [matchr, match?](matchr.md) - Matches a string against a regular expression.
* [move](move.md) - Moves a cursor to a given position
* [noeval](noeval.md) - Immediately replies, children are not evaluated
* [noret](noret.md) - executes its children, but doesn't alter the received f.ret
* [rand](rand.md) - Returns a randomly generated number.
* [sequence, _apply, begin](sequence.md) - Executes child expressions in sequence.

## unit

* [cancel, kill](cancel.md) - Cancels an execution branch
* [concurrence](concurrence.md) - Executes its children concurrently.
* [graft, import](graft.md) - Graft a subtree into the current flo
* [on](on.md) - Traps a signal by name
* [schedule](schedule.md) - Schedules a function
* [sleep](sleep.md) - Makes a branch of an execution sleep for a while.

