# gleamer

[![Package Version](https://img.shields.io/hexpm/v/gleamer)](https://hex.pm/packages/gleamer)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gleamer/)

```sh
gleam add gleamer@1
```

Output all data from a csv

```curl
curl -X POST "http://localhost:8080/read/payment" \
-F files=@my_royalty_statement.csv
```

Summarize payments with matching title\_

```curl
curl -X POST "http://localhost:8080/read/song/peaches" \
-F files=@my_royalty_statement.csv
```

Further documentation can be found at <https://hexdocs.pm/gleamer>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
