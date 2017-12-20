LLI="lli"
LLC="llc"
CC="cc"
CQM="./cqm.native"

Run() {
    echo $* 1>&2
    eval $* || {
	SignalError "$1 failed on $*"
	return 1
    }
}

Compile() {
  basename=`echo $1 | sed 's/.*\\///
                           s/.cqm//'`
  echo ${basename}
  Run "cat" "lib/*.cqm" "$1" "|" "$CQM" ">" "${basename}.ll" &&
  Run "$LLC" "${basename}.ll" ">" "${basename}.s" &&
  Run "$CC" "-o" "${basename}.exe" "${basename}.s" "printbig.o" "eigen_mnist.o" "-Llib/src" "-leigentest" "-lm"
}

Compile $1
