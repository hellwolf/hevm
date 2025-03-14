# `hevm equivalence`

```
Usage: hevm equivalence --code-a TEXT --code-b TEXT [--sig TEXT]
                        [--arg STRING]... [--calldata TEXT]
                        [--smttimeout NATURAL] [--max-iterations INTEGER]
                        [--solver TEXT] [--smtoutput] [--smtdebug] [--debug]
                        [--trace] [--ask-smt-iterations INTEGER]
                        [--num-cex-fuzz INTEGER]
                        [--loop-detection-heuristic LOOPHEURISTIC]
                        [--abstract-arithmetic] [--abstract-memory]

Available options:
  -h,--help                Show this help text
  --code-a TEXT            Bytecode of the first program
  --code-b TEXT            Bytecode of the second program
  --sig TEXT               Signature of types to decode / encode
  --arg STRING             Values to encode
  --calldata TEXT          Tx: calldata
  --smttimeout NATURAL     Timeout given to SMT solver in seconds (default: 300)
  --max-iterations INTEGER Number of times we may revisit a particular branching
                           point. Default is 5. Setting to -1 allows infinite looping
  --solver TEXT            Used SMT solver: z3 (default), cvc5, or bitwuzla
  --smtoutput              Print verbose smt output
  --smtdebug               Print smt queries sent to the solver
  --debug                  Debug printing of internal behaviour
  --trace                  Dump trace
  --ask-smt-iterations INTEGER
                           Number of times we may revisit a particular branching
                           point before we consult the smt solver to check
                           reachability (default: 1) (default: 1)
  --num-cex-fuzz INTEGER   Number of fuzzing tries to do to generate a
                           counterexample (default: 3) (default: 3)
  --loop-detection-heuristic LOOPHEURISTIC
                           Which heuristic should be used to determine if we are
                           in a loop: StackBased (default) or Naive
                           (default: StackBased)
```

Symbolically execute both the code given in `--code-a` and `--code-b` and try
to prove equivalence between their outputs and storages. Extracting bytecode
from solidity contracts can be done via, e.g.:

```
hevm equivalence \
    --code-a $(solc --bin-runtime "contract1.sol" | tail -n1) \
    --code-b $(solc --bin-runtime "contract2.sol" | tail -n1)
```
If `--sig` is given, calldata is assumed to take the form of the function
given. If `--calldata` is provided, a specific, concrete calldata is used. If
neither is provided, a fully abstract calldata of at most `2**64` byte is
assumed. Note that a `2**64` byte calldata would go over the gas limit, and
hence should cover all meaningful cases.
