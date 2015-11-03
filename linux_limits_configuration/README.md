### List all limit configurations
```
ulimit -n
```
Sample output:
```
core file size          (blocks, -c) 0
data seg size           (kbytes, -d) unlimited
scheduling priority             (-e) 0
file size               (blocks, -f) unlimited
pending signals                 (-i) 7859
max locked memory       (kbytes, -l) 64
max memory size         (kbytes, -m) unlimited
open files                      (-n) 64000
pipe size            (512 bytes, -p) 8
POSIX message queues     (bytes, -q) 819200
real-time priority              (-r) 0
stack size              (kbytes, -s) 8192
cpu time               (seconds, -t) unlimited
max user processes              (-u) 32000
virtual memory          (kbytes, -v) unlimited
file locks                      (-x) unlimited
```

### Meanings of those limits

* **core file size** Limits the size of `core file` that a process left behind
after it was terminated by segmentation faults or unexpected fatal errors. `core
file` is a file contains entire memory space of the process at the time it is
terminated. It is usually used to examine the process state with a kind of
debugger such as gdb. In most case, just leave it 0.

* **data seg size** (data segment size) The amount of memory allowed for a
process to allocate on the heap (malloc, calloc, new, object creation...).

* **scheduling priority** TODO: I don't really know this limit yet

* **file size** Simply max size allowed for a single file

* **pending signals** Maximum number of pending signals (not yet handled signals
when the process is sleep) such as sigterm, sigkill, sigstop, this limit is
counted for one user ID.

* **max locked memory** Maximum amount of memory that can be locked down (
usually specified with physical address). You don't usually need to change this.

* **max memory size** TODO: It seems easy to understand but I couldn't find
any documents about this.

* **open files** Maximum number of opened file at the same time. This counts by
file descriptor (normal file, socket, ...). It's very important to raise this
number to high value (64k, 100k or even more) if the server needs to handle
many concurrent connections.

* **pipe size** Size for a pipe-like file (pipe, FIFO buffer), if a command `a`
need to transfer its data to command `b` (such as a | b), `a`'s data is
buffered to the pipe size before transmission. You can just leave this as default.

* **POSIX message queues** Maximum bytes for POSIX message queues for one user ID.

* **real-time priority** TODO: I don't understand this configuration

* **stack-size** Maximum amount of memory that a process can allocate on the stack
(such as for local variables, recursive function calls, ...).

* **cpu-time** Maximum number of seconds a process can use CPU executing processor
instructions. You can just leave this configuration unlimited.

* **max-user-process** Maximum number of processes permitted for current user to
open at the same time. You should set this configuration to high number (such as
32K) just in case your application yields a lot of application processes.

* **virtual memory** Maximum virtual memory that the OS can allocate. Trying to
allocate more than this configuration will fail with out-of-memory error.

* **file locks** Maximum number of locked files at the same time.
