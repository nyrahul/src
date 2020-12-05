## Tracing Linux kernel function

Use trace-cmd which uses ftrace backend. Simplifies things.

`sudo apt-get install trace-cmd`


### trace-cmd profile
```
sudo trace-cmd profile
Hit Ctrl^C to stop recording

task: swapper/0-0
  Event: sched_switch:R (72572) Total: 5373724722 Avg: 74046 Max: 29344184(ts:163676.340735) Min:0(ts:163673.824865)
          |
          + schedule (0xffffffff9cab215c)
          |   99% (66904) time:3113149019 max:21992103(ts:163678.368896) min:0(ts:163673.850195) avg:46531
          |    schedule_preempt_disabled (0xffffffff9cab240e)
          |    cpu_startup_entry (0xffffffff9c2d00b5)
          |     |
          |     + start_secondary (0xffffffff9c2545f7)
          |     |   51% (31592) time:1595162797 max:21992103(ts:163678.368896) min:0(ts:163673.850195) avg:50492
          |     |
          |     + rest_init (0xffffffff9caa97f7)
          |         49% (35312) time:1517986222 max:20813582(ts:163674.296260) min:0(ts:163673.824871) avg:42987
          |          start_kernel (0xffffffff9d1bdf70)
          |          x86_64_start_reservations (0xffffffff9d1bd26b)
          |          x86_64_start_kernel (0xffffffff9d1bd3a9)
          |
          |
          |
          + ttwu_do_activate (0xffffffff9c2b60df)
              1% (31) time:36737464 max:4724302(ts:163677.068497) min:8265(ts:163677.980821) avg:1185079
               try_to_wake_up (0xffffffff9c2b6d2a)
                |
                + default_wake_function (0xffffffff9c2b6fd2)
                |   58% (16) time:21313079 max:4454947(ts:163674.976879) min:8265(ts:163677.980821) avg:1332067
                |    autoremove_wake_function (0xffffffff9c2cf892)
                |    __wake_up_common (0xffffffff9c2cf2c3)
                |    __wake_up (0xffffffff9c2cf339)
                |    rb_wake_up_waiters (0xffffffff9c35ccd6)
                |    irq_work_run_list (0xffffffff9c38d0be)
                |    irq_work_run (0xffffffff9c38d108)
                |    smp_trace_irq_work_interrupt (0xffffffff9cab9fd2)
                |    trace_irq_work_interrupt (0xffffffff9cab9cbe)
                |     |
                |     + default_idle (0xffffffff9cab6460)
                |     |   77% (8) time:16417266 max:4454947(ts:163674.976879) min:8265(ts:163677.980821) avg:2052158
                |     |    arch_cpu_idle (0xffffffff9c239935)
                |     |    default_idle_call (0xffffffff9cab68d3)
                |     |    cpu_startup_entry (0xffffffff9c2d00ce)
                |     |     |
                |     |     + rest_init (0xffffffff9caa97f7)
                |     |     |   55% (5) time:9031933 max:3795309(ts:163674.351421) min:233098(ts:163676.999952) avg:1806386
                |     |     |    start_kernel (0xffffffff9d1bdf70)
                |     |     |    x86_64_start_reservations (0xffffffff9d1bd26b)
                |     |     |    x86_64_start_kernel (0xffffffff9d1bd3a9)
                |     |     |
                |     |     + start_secondary (0xffffffff9c2545f7)
                |     |         45% (3) time:7385333 max:4454947(ts:163674.976879) min:8265(ts:163677.980821) avg:2461777
                |     |
				...
```

### trace-cmd list -f
Lists all the functions that could be traced
```
sudo trace-cmd list -f
anitize_boot_params.constprop.3
run_init_process
try_to_run_init_process
initcall_blacklisted
do_one_initcall
match_dev_by_uuid
rootfs_mount
name_to_dev_t
init_linuxrc
init_linuxrc
calibration_delay_done
calibrate_delay
syscall_trace_enter
exit_to_usermode_loop
syscall_slow_exit_work
do_syscall_64
do_int80_syscall_32
do_fast_syscall_32
vgetcpu_cpu_init
vvar_fault
vdso_fault
map_vdso
map_vdso_randomized
vgetcpu_online
vdso_mremap
map_vdso_once
arch_setup_additional_pages
compat_arch_setup_additional_pages
update_vsyscall_tz
update_vsyscall
gate_vma_name
write_ok_or_segv.part.3
warn_bad_vsyscall
vsyscall_enabled
emulate_vsyscall
get_gate_vma
in_gate_area
in_gate_area_no_mm
x86_pmu_extra_regs
x86_pmu_disable
collect_events
x86_pmu_prepare_cpu
x86_pmu_dead_cpu
x86_pmu_starting_cpu
x86_pmu_dying_cpu
x86_pmu_event_idx
...
```

### trace-cmd record -p function -l <function-name>
```
sudo trace-cmd record -p function -l __do_page_fault
  plugin 'function'
Hit Ctrl^C to stop recording
```
```
sudo trace-cmd report
cpus=2
       trace-cmd-24174 [001] 164303.595438: function:             __do_page_fault
       trace-cmd-24174 [001] 164303.595444: function:             __do_page_fault
       trace-cmd-24176 [001] 164303.595462: function:             __do_page_fault
       trace-cmd-24175 [000] 164303.595462: function:             __do_page_fault
 systemd-journal-445   [000] 164303.715613: function:             __do_page_fault
         coredns-9550  [000] 164303.814683: function:             __do_page_fault
         coredns-9550  [000] 164303.814693: function:             __do_page_fault
  kube-scheduler-32257 [001] 164304.526560: function:             __do_page_fault
  kube-scheduler-32257 [001] 164304.526567: function:             __do_page_fault
 systemd-journal-445   [001] 164304.734010: function:             __do_page_fault
 containerd-shim-8038  [001] 164305.382821: function:             __do_page_fault
 containerd-shim-8042  [000] 164305.382827: function:             __do_page_fault
 containerd-shim-8038  [001] 164305.382827: function:             __do_page_fault
 containerd-shim-8038  [001] 164305.382829: function:             __do_page_fault
 containerd-shim-8038  [001] 164305.382830: function:             __do_page_fault
 containerd-shim-8038  [001] 164305.382831: function:             __do_page_fault
 containerd-shim-8038  [001] 164305.382832: function:             __do_page_fault
 containerd-shim-8038  [001] 164305.382833: function:             __do_page_fault
 containerd-shim-8038  [001] 164305.382834: function:             __do_page_fault
 containerd-shim-8042  [000] 164305.382835: function:             __do_page_fault
 containerd-shim-8042  [000] 164305.382836: function:             __do_page_fault
...
```

### trace-cmd stream -p function -P <pid>
```
sudo trace-cmd stream -p function -P 9936
Hit Ctrl^C to stop recording
          <idle>-0     [001] 164722.894037: function:             switch_mm_irqs_off
          <idle>-0     [001] 164722.894040: function:                load_new_mm_cr3
            sshd-9936  [001] 164722.894041: function:             finish_task_switch
            sshd-9936  [001] 164722.894042: function:             smp_irq_work_interrupt
            sshd-9936  [001] 164722.894043: function:                irq_enter
            sshd-9936  [001] 164722.894043: function:                   rcu_irq_enter
            sshd-9936  [001] 164722.894044: function:             __wake_up
            sshd-9936  [001] 164722.894044: function:                _raw_spin_lock_irqsave
            sshd-9936  [001] 164722.894044: function:                __wake_up_common
            sshd-9936  [001] 164722.894044: function:                _raw_spin_unlock_irqrestore
            sshd-9936  [001] 164722.894044: function:             __wake_up
            sshd-9936  [001] 164722.894044: function:                _raw_spin_lock_irqsave
            sshd-9936  [001] 164722.894044: function:                __wake_up_common
            sshd-9936  [001] 164722.894045: function:                   autoremove_wake_function
            sshd-9936  [001] 164722.894045: function:                      default_wake_function
            sshd-9936  [001] 164722.894045: function:                         try_to_wake_up
            sshd-9936  [001] 164722.894045: function:                            _raw_spin_lock_irqsave
            sshd-9936  [001] 164722.894046: function:                            select_task_rq_fair
            sshd-9936  [001] 164722.894046: function:                               select_idle_sibling
            sshd-9936  [001] 164722.894046: function:                                  idle_cpu
            sshd-9936  [001] 164722.894046: function:                                  idle_cpu
            sshd-9936  [001] 164722.894046: function:                                  idle_cpu
            sshd-9936  [001] 164722.894047: function:                            set_task_cpu
            sshd-9936  [001] 164722.894047: function:                               migrate_task_rq_fair
            sshd-9936  [001] 164722.894047: function:                                  remove_entity_load_avg
            sshd-9936  [001] 164722.894047: function:                               set_task_rq_fair
            sshd-9936  [001] 164722.894047: function:                                  set_task_rq_fair.part.77
            sshd-9936  [001] 164722.894048: function:                            _raw_spin_lock
            sshd-9936  [001] 164722.894048: function:                            ttwu_do_activate
            sshd-9936  [001] 164722.894048: function:                               activate_task
            sshd-9936  [001] 164722.894048: function:                                  update_rq_clock.part.83
            sshd-9936  [001] 164722.894048: function:                                  enqueue_task_fair
            sshd-9936  [001] 164722.894048: function:                                     enqueue_entity
            sshd-9936  [001] 164722.894048: function:                                        update_curr
            sshd-9936  [001] 164722.894048: function:             __compute_runnable_contrib
            sshd-9936  [001] 164722.894049: function:                                        attach_entity_load_avg
            sshd-9936  [001] 164722.894049: function:                                        account_entity_enqueue
            sshd-9936  [001] 164722.894049: function:                                        update_cfs_shares
            sshd-9936  [001] 164722.894049: function:                                        __enqueue_entity
            sshd-9936  [001] 164722.894049: function:                                     enqueue_entity
            sshd-9936  [001] 164722.894049: function:                                        update_curr
            sshd-9936  [001] 164722.894049: function:                                        __compute_runnable_contrib
            sshd-9936  [001] 164722.894050: function:                __compute_runnable_contrib.part.62
            sshd-9936  [001] 164722.894050: function:             __compute_runnable_contrib
            sshd-9936  [001] 164722.894050: function:                                        account_entity_enqueue
            sshd-9936  [001] 164722.894050: function:                                        update_cfs_shares
            sshd-9936  [001] 164722.894050: function:                                        __enqueue_entity
            sshd-9936  [001] 164722.894050: function:                                     hrtick_update
            sshd-9936  [001] 164722.894050: function:                               ttwu_do_wakeup
            sshd-9936  [001] 164722.894051: function:                                  check_preempt_curr
            sshd-9936  [001] 164722.894051: function:                                     resched_curr
            sshd-9936  [001] 164722.894051: function:                                        native_smp_send_reschedule
            sshd-9936  [001] 164722.894051: function:                                           x2apic_send_IPI
			...
```
9936 is the pid of sshd process
