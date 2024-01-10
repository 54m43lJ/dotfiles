if status is-interactive
    # Commands to run in interactive sessions can go here
end
alias vi=nvim
alias D:='cd /mnt/MAIN/'
alias venv='source venv/bin/activate.fish'
if test -n $(which python)
    alias newvenv='python -m venv .venv'
else
    alias newvenv='python3 -m venv .venv'
