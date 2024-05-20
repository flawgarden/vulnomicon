SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BASE_DIR="$(cd $SCRIPT_DIR/.. && pwd)"

cd $BASE_DIR;

echo "Warning: reality-check is a big benchmark"
echo "Running all avaiable tools on it will take about 24 hours"
echo -n "Proceed (yes/no)? "
read -r proceed

if [ ! $proceed = "yes" ]; then
    echo "Exiting"
    exit 0
fi

if [ ! -f "bentoo" ]; then
    echo "Please run bentoo.sh beforehand"
fi

if [ ! -d "tool_runners" ]; then
    echo "Please run bentoo.sh beforehand"
fi

PATH=$PATH:$(pwd)

bentoo template --tools tool_runners/tools.toml reality-check/benchmark > reality-check/benchmark/runs.toml
bentoo bench --tools tool_runners/tools.toml --runs reality-check/benchmark/runs.toml --timeout 1200 reality-check-output
