# Random Password Generator
A collection of scripts that generate random strings of text, each accounting for a different scenario.
## rpg-urandom.sh
### Scenario: `/dev/random` or `/dev/urandom` is available
`rpg-urandom.sh` uses the built-in RNG present on most Linux/Unix systems (including Android). \
This is much faster compared to `rpg-bash.sh` and can generate thousands of new passwords in seconds. \
It is also the most secure option and should preferred over `rpg-bash.sh`.
## rpg-openssl.sh
### Scenario: `/dev/random` and `/dev/urandom` are unavailable
`rpg-openssl.sh` uses the RNG found in OpenSSL. \
It is also secure and can be used as an alternative to `rpg-urandom.sh`
## rpg-bash.sh
### Scenario: `/dev/urandom`, `/dev/random`, and `/usr/bin/openssl` are unavailable
`rpg-bash.sh` is a script that only uses Bash's built-in functions to generate random strings. \
This means that no external utilities (save for `nproc`) are needed to run it; only the Bash shell is required.
### Note #1
You can remove the `nproc` dependency by commenting out the `Threads=$(( $(nproc) / 2 ))` variable.
### Note #2
This script is also compatible with `zsh`. \
Simply change `#!/bin/bash` at the start of the script to `#!/bin/zsh` and it should work without issues.
### Note #3
The RNG function found within Bash and ZSH are **less secure** than the alternatives listed above. \
Only use this if the alternatives are not viable.
