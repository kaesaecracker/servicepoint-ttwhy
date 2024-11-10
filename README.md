# servicepoint-ttwhy

Pipe text to the servicepoint-display.

For more information, see [here](https://github.com/cccb/servicepoint).

```shell
dmesg --follow > servicepoint-tty
```

## Running

With nix: `nix run github:kaesaecracker/servicepoint-ttwhy`

Without nix: checkout the repository and execute `cargo run`

```
Usage: servicepoint-ttwhy [OPTIONS]

Options:
  -d, --destination <DESTINATION>  Address of the display. Try '172.23.42.29:2342'. [default: localhost:2342]
  -f, --fast...                    Increase speed, but loose some packages. Add multiple times to go faster.
  -h, --help                       Print help
```
