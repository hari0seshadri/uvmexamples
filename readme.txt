┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              TOP (testbench.sv)                                    						    │
│  ┌─────────────────────────────────────────────────────────────────────────────┐     │
│  │                           Initial Blocks                                    						 │   │
│  │  • Clock Generator (10ns period)                                                              │   │
│  │  • Reset Generator (3 cycles)                                                                 │   │
│  │  • UVM Config DB: set("dut_vi", dut_if1)                                                      │   │
│  │  • run_test()                                                                                 │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│  ┌──────────────────────────┐         ┌──────────────────────────┐                  │
│  │      dut_if (interface)  │         │    dut (design module)   │                  │
│  │  ┌────────────────────┐  │         │  ┌────────────────────┐  │                  │
│  │  │ clock              │◄─┼─────────┼──│ dif.clock          │  │                  │
│  │  │ reset              │◄─┼─────────┼──│ dif.reset          │  │                  │
│  │  │ cmd                │◄─┼─────────┼──│ dif.cmd            │  │                  │
│  │  │ addr[7:0]          │◄─┼─────────┼──│ dif.addr           │  │                  │
│  │  │ data[7:0]          │◄─┼─────────┼──│ dif.data           │  │                  │
│  │  └────────────────────┘  │         │  └────────────────────┘  │                  │
│  └──────────────────────────┘         └──────────────────────────┘                  │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                              ▲
                                              │ (virtual interface)
                                              │
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              UVM TESTBENCH HIERARCHY                                 │
│                                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                           my_test (base test)                               │   │
│  │  ┌─────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                     my_dut_config (configuration)                   │   │   │
│  │  │  • virtual dut_if dut_vi  ◄─────────── connects to top.dut_if1      │   │   │
│  │  └─────────────────────────────────────────────────────────────────────┘   │   │
│  │                                                                              │   │
│  │  ┌────────────────────────────────────────────────────────────────────┐    │   │
│  │  │                         my_env_h (my_env)                          │    │   │
│  │  │  ┌──────────────────────────────────────────────────────────────┐  │    │   │
│  │  │  │                   my_agent_h (my_agent)                     │  │    │   │
│  │  │  │  ┌──────────────────────────────────────────────────────┐   │  │    │   │
│  │  │  │  │  my_sequencer_h (uvm_sequencer #(my_transaction))   │   │  │    │   │
│  │  │  │  │  • seq_item_export                                  │   │  │    │   │
│  │  │  │  └───────────────────────────┬──────────────────────────┘   │  │    │   │
│  │  │  │                              │ (seq_item_port.connect)       │  │    │   │
│  │  │  │  ┌───────────────────────────▼──────────────────────────┐   │  │    │   │
│  │  │  │  │         my_driver_h (my_driver)                     │   │  │    │   │
│  │  │  │  │  • virtual dut_if dut_vi ──────┐                    │   │  │    │   │
│  │  │  │  │  • gets transactions           │                    │   │  │    │   │
│  │  │  │  │  • drives DUT pins             │                    │   │  │    │   │
│  │  │  │  └────────────────────────────────┼────────────────────┘   │  │    │   │
│  │  │  │                                   │ (drives)               │  │    │   │
│  │  │  │  ┌────────────────────────────────▼────────────────────┐   │  │    │   │
│  │  │  │  │         my_monitor_h (my_monitor)                  │   │  │    │   │
│  │  │  │  │  • virtual dut_if dut_vi ──────┘                    │   │  │    │   │
│  │  │  │  │  • samples DUT pins                                 │   │  │    │   │
│  │  │  │  │  • creates transactions                             │   │  │    │   │
│  │  │  │  │  • analysis_port: aport                            │   │  │    │   │
│  │  │  │  └───────────────────────────┬──────────────────────────┘   │  │    │   │
│  │  │  │                              │ (aport)                      │  │    │   │
│  │  │  └──────────────────────────────┼──────────────────────────────┘  │    │   │
│  │  │                                 │                                 │    │   │
│  │  │                                 │ (aport.connect)                 │    │   │
│  │  │  ┌──────────────────────────────▼──────────────────────────────┐  │    │   │
│  │  │  │            my_subscriber_h (my_subscriber)                 │  │    │   │
│  │  │  │  • analysis_export                                         │  │    │   │
│  │  │  │  • covergroup: cover_bus                                   │  │    │   │
│  │  │  │    - coverpoint cmd                                        │  │    │   │
│  │  │  │    - coverpoint addr (16 bins)                             │  │    │   │
│  │  │  │    - coverpoint data (16 bins)                             │  │    │   │
│  │  │  │  • write() function: prints and samples coverage           │  │    │   │
│  │  │  └────────────────────────────────────────────────────────────┘  │    │   │
│  │  └────────────────────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                         EXTENDED TESTS                                       │   │
│  ├─────────────────────────────────────────────────────────────────────────────┤   │
│  │  test1 extends my_test                                                     │   │
│  │  └── run_phase: executes read_modify_write sequence                        │   │
│  │                                                                              │   │
│  │  test2 extends my_test                                                     │   │
│  │  └── run_phase: executes seq_of_commands sequence (n=2 to 4)               │   │
│  │                                                                              │   │
│  │  test3 extends my_test                                                     │   │
│  │  └── run_phase: executes seq_of_commands sequence (n=11 to 19)             │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              DATA FLOW DIAGRAM                                       │
└─────────────────────────────────────────────────────────────────────────────────────┘

  TEST SEQUENCE FLOW:
  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
  │   Test       │    │  Sequencer   │    │   Driver     │    │     DUT      │
  │  (test1/2/3) │───▶│ (sequencer)  │───▶│  (driver)    │───▶│   (dut)      │
  │              │    │              │    │              │    │              │
  │ • Creates    │    │ • Stores     │    │ • Gets tx    │    │ • Receives   │
  │   sequence   │    │   sequence   │    │   from seq   │    │   pin values │
  │ • Starts     │    │ • Provides   │    │ • Drives     │    │ • Prints     │
  │   sequence   │    │   tx items   │    │   DUT pins   │    │   info       │
  └──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘

  MONITOR FLOW:
  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
  │     DUT      │    │   Monitor    │    │  Subscriber  │
  │   (dut)      │───▶│  (monitor)   │───▶│ (subscriber) │
  │              │    │              │    │              │
  │ • Drives     │    │ • Samples    │    │ • Receives   │
  │   pins       │    │   DUT pins   │    │   tx         │
  │              │    │ • Creates    │    │ • Prints tx  │
  │              │    │   tx         │    │ • Samples    │
  │              │    │ • Writes to  │    │   coverage   │
  │              │    │   analysis   │    │              │
  │              │    │   port       │    │              │
  └──────────────┘    └──────────────┘    └──────────────┘

  CONFIGURATION FLOW:
  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
  │     Top      │    │  Test        │    │    Config    │    │  Driver/     │
  │ (testbench)  │───▶│  (my_test)   │───▶│  Database    │    │  Monitor     │
  │              │    │              │    │              │    │              │
  │ • Creates    │    │ • Gets       │    │ • Stores     │    │ • Gets       │
  │   dut_if     │    │   dut_vi     │    │   dut_config │    │   dut_config │
  │ • Sets       │    │ • Creates    │    │   object     │    │ • Extracts   │
  │   dut_vi in  │    │   config     │    │              │    │   dut_vi     │
  │   config DB  │    │   object     │    │              │    │              │
  │              │    │ • Sets       │    │              │    │              │
  │              │    │   config in  │    │              │    │              │
  │              │    │   config DB  │    │              │    │              │
  └──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘

uvm_top
│
├── my_test (base test)
│   ├── dut_config_0 (my_dut_config)
│   │   └── dut_vi (virtual dut_if) → points to top.dut_if1
│   │
│   └── my_env_h (my_env)
│       ├── my_agent_h (my_agent)
│       │   ├── my_sequencer_h (uvm_sequencer#(my_transaction))
│       │   ├── my_driver_h (my_driver)
│       │   │   └── dut_vi (virtual dut_if) → points to top.dut_if1
│       │   └── my_monitor_h (my_monitor)
│       │       ├── aport (uvm_analysis_port#(my_transaction))
│       │       └── dut_vi (virtual dut_if) → points to top.dut_if1
│       │
│       └── my_subscriber_h (my_subscriber)
│           └── analysis_export (uvm_analysis_export)
│
├── test1 (extends my_test) [selected by +UVM_TESTNAME=test1]
│   └── run_phase: executes read_modify_write sequence
│
├── test2 (extends my_test) [selected by +UVM_TESTNAME=test2]
│   └── run_phase: executes seq_of_commands sequence (n=2-4)
│
└── test3 (extends my_test) [selected by +UVM_TESTNAME=test3]
    └── run_phase: executes seq_of_commands sequence (n=11-19)

Sequences Hierarchy:
┌─────────────────────────────────────────────────────────────────┐
│                    seq_of_commands                              │
│  (uvm_sequence #(my_transaction))                              │
│  • random variable: n (number of iterations)                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              read_modify_write (n times)                │   │
│  │  (uvm_sequence #(my_transaction))                      │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │     my_transaction (first write)                │   │   │
│  │  │     • cmd = 1                                   │   │   │
│  │  │     • random addr (0-255)                       │   │   │
│  │  │     • random data (0-255)                       │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │     my_transaction (second write)               │   │   │
│  │  │     • cmd = 1                                   │   │   │
│  │  │     • same addr as first                        │   │   │
│  │  │     • data = first.data + 1                     │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        UVM PHASE EXECUTION                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  build_phase ──▶ connect_phase ──▶ start_of_simulation_phase       │
│       │               │                      │                       │
│       ▼               ▼                      ▼                       │
│  • Create config  • Connect TLM      • Set verbosity               │
│  • Create env       ports            • Open log file               │
│  • Create agent   • Connect agent    • Configure reporting         │
│  • Create driver     to subscriber                                  │
│  • Create monitor                                                    │
│  • Create subscriber                                                │
│                                                                      │
│  ───────────────────────────────────────────────────────────────    │
│                                                                      │
│  run_phase ────────────────────────────────────────────────────►    │
│       │                                                             │
│       ▼                                                             │
│  • raise_objection                                                  │
│  • start sequence                                                   │
│  • wait for completion                                              │
│  • drop_objection                                                   │
│                                                                      │
│  ───────────────────────────────────────────────────────────────    │
│                                                                      │
│  extract_phase ──▶ check_phase ──▶ report_phase ──▶ final_phase   │
│       (coverage extraction)  (scoreboard checks)  (final reports)   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘


==========
TESTBENCH HIERARCHY DIAGRAM
============================

[TOP LEVEL]
================================================================================
top (testbench.sv)
|
+-- dut_if (interface)
|   |
|   +-- clock
|   +-- reset
|   +-- cmd
|   +-- addr[7:0]
|   +-- data[7:0]
|
+-- dut (design under test)
|   |
|   +-- dif (connected to dut_if)
|
+-- initial block: clock generator (5ns period)
+-- initial block: reset generator (3 cycles)
+-- initial block: UVM test runner
    |
    +-- uvm_config_db::set("dut_vi", dut_if1)
    +-- run_test()


[UVM TEST HIERARCHY]
================================================================================
uvm_top
|
+-- my_test (base test class)
    |
    +-- dut_config_0 (my_dut_config object)
    |   |
    |   +-- dut_vi (virtual interface) -----> points to top.dut_if1
    |
    +-- my_env_h (my_env object)
        |
        +-- my_agent_h (my_agent object)
        |   |
        |   +-- my_sequencer_h (uvm_sequencer#(my_transaction))
        |   |
        |   +-- my_driver_h (my_driver object)
        |   |   |
        |   |   +-- dut_vi (virtual interface) -----> points to top.dut_if1
        |   |   +-- seq_item_port ---> connected to sequencer
        |   |
        |   +-- my_monitor_h (my_monitor object)
        |       |
        |       +-- aport (uvm_analysis_port#(my_transaction))
        |       +-- dut_vi (virtual interface) -----> points to top.dut_if1
        |
        +-- my_subscriber_h (my_subscriber object)
            |
            +-- analysis_export <--- connected to monitor.aport
            +-- cover_bus (covergroup)
                |
                +-- coverpoint cmd
                +-- coverpoint addr (16 bins)
                +-- coverpoint data (16 bins)


[EXTENDED TEST CLASSES]
================================================================================
test1 extends my_test
|
+-- run_phase: executes read_modify_write sequence (1 iteration)

test2 extends my_test
|
+-- run_phase: executes seq_of_commands sequence (n = 2 to 4)

test3 extends my_test
|
+-- run_phase: executes seq_of_commands sequence (n = 11 to 19)


[SEQUENCE HIERARCHY]
================================================================================
seq_of_commands (uvm_sequence)
|
+-- random variable: n (number of iterations)
|
+-- body() task
    |
    +-- repeat (n times)
        |
        +-- read_modify_write sequence (created n times)
            |
            +-- body() task
                |
                +-- Transaction 1 (first write)
                |   |
                |   +-- cmd = 1
                |   +-- addr = random (0-255)
                |   +-- data = random (0-255)
                |
                +-- Transaction 2 (second write)
                    |
                    +-- cmd = 1
                    +-- addr = same as Transaction 1
                    +-- data = Transaction 1.data + 1


[DATA FLOW DIAGRAM]
================================================================================

Direction: TEST -> SEQUENCER -> DRIVER -> DUT

    [Test]          [Sequencer]        [Driver]           [DUT]
    (test1)         (my_sequencer)     (my_driver)        (dut)
       |                  |                 |                |
       |--creates seq---->|                 |                |
       |                  |                 |                |
       |--starts seq----->|                 |                |
       |                  |                 |                |
       |                  |--provides tx--->|                |
       |                  |                 |                |
       |                  |                 |--drives pins-->|
       |                  |                 |                |
       |                  |                 |                |--prints info


Direction: DUT -> MONITOR -> SUBSCRIBER

    [DUT]           [Monitor]         [Subscriber]
    (dut)           (my_monitor)      (my_subscriber)
       |                  |                  |
       |--samples pins--->|                  |
       |                  |                  |
       |                  |--creates tx----->|
       |                  |                  |
       |                  |--writes tx------>|
       |                  |                  |
       |                  |                  |--prints transaction
       |                  |                  |
       |                  |                  |--samples coverage


[CONFIGURATION FLOW]
================================================================================

Step 1: Top Level Sets Interface
    [top] --set("dut_vi", dut_if1)--> [uvm_config_db]

Step 2: Test Retrieves Interface and Creates Config Object
    [test] --get("dut_vi")-----------> [uvm_config_db]
    [test] --creates my_dut_config--> [dut_config_0]
    [test] --set("dut_config")-------> [uvm_config_db]

Step 3: Driver/Monitor Retrieve Config and Extract Interface
    [driver] --get("dut_config")-----> [uvm_config_db]
    [driver] --extract dut_vi-------> [dut_config_0.dut_vi]


[TLM (TRANSACTION LEVEL MODELING) CONNECTIONS]
================================================================================

    my_agent
    |
    +-- my_monitor.aport ---------------------------+
        |                                           |
        | (aport.connect)                           |
        |                                           v
    my_agent.aport -----------------------> my_subscriber.analysis_export
        |
        | (connected in my_env.connect_phase)

    my_driver.seq_item_port <----------> my_sequencer.seq_item_export
        |
        | (connected in my_agent.connect_phase)


[UVM PHASE EXECUTION ORDER]
================================================================================

    build_phase
        |
        v
    connect_phase
        |
        v
    start_of_simulation_phase
        |
        v
    run_phase
        |
        |-- raise_objection
        |-- start sequence
        |-- wait for sequence completion
        |-- drop_objection
        |
        v
    extract_phase
        |
        v
    check_phase
        |
        v
    report_phase
        |
        v
    final_phase


[COMPONENT CONTAINMENT TREE]
================================================================================

uvm_top
+-- my_test
    +-- dut_config_0 (configuration object)
    +-- my_env
        +-- my_agent
            +-- my_sequencer
            +-- my_driver
            +-- my_monitor
        +-- my_subscriber


[CONNECTION MATRIX]
================================================================================

Component A          | Connection Type        | Component B
---------------------|------------------------|-------------------
my_test              | configuration          | dut_config_0
my_test              | contains               | my_env
my_env               | contains               | my_agent
my_env               | contains               | my_subscriber
my_agent             | contains               | my_sequencer
my_agent             | contains               | my_driver
my_agent             | contains               | my_monitor
my_driver            | TLM port               | my_sequencer
my_monitor.aport     | TLM port               | my_agent.aport
my_agent.aport       | TLM port               | my_subscriber.analysis_export
dut_config_0.dut_vi  | virtual interface      | top.dut_if1
my_driver.dut_vi     | virtual interface      | top.dut_if1
my_monitor.dut_vi    | virtual interface      | top.dut_if1


[SEQUENCE EXECUTION EXAMPLE]
================================================================================

For test2 with n=3 (randomized within 2-4):

    seq_of_commands starts
        |
        +-- Iteration 1: read_modify_write
        |       |
        |       +-- Transaction 1: cmd=1, addr=45, data=23
        |       +-- Transaction 2: cmd=1, addr=45, data=24
        |
        +-- Iteration 2: read_modify_write
        |       |
        |       +-- Transaction 1: cmd=1, addr=12, data=67
        |       +-- Transaction 2: cmd=1, addr=12, data=68
        |
        +-- Iteration 3: read_modify_write
                |
                +-- Transaction 1: cmd=1, addr=89, data=45
                +-- Transaction 2: cmd=1, addr=89, data=46

    Total transactions generated: 6 (2 per iteration * 3 iterations)


[FILE DEPENDENCY MAP]
================================================================================

my_testbench_pkg.sv
|
+-- my_config.sv (defines my_dut_config)
+-- my_sequences.sv (defines my_transaction, read_modify_write, seq_of_commands)
+-- my_driver.sv (defines my_driver)
+-- my_monitor.sv (defines my_monitor)
+-- my_subscriber.sv (defines my_subscriber)
+-- my_agent.sv (defines my_agent)
+-- my_env.sv (defines my_env)
+-- my_test.sv (defines my_test, test1, test2, test3)

testbench.sv
|
+-- imports my_testbench_pkg
+-- instantiates dut_if and dut
+-- contains clock/reset generators
+-- calls run_test()

dut.sv
|
+-- defines dut_if interface
+-- defines dut module
+-- prints info on clock edges
