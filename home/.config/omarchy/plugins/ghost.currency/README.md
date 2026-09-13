# Currency

Currency converter for the Omarchy bar. Rates come from [Frankfurter](https://frankfurter.dev) (central-bank data, no API key).

Bar: a single banknote icon; hover to preview the conversion.

- left click: converter
- right click: swap direction
- middle click: refresh rates

Panel: a tinted result card with a large amount, currency symbol, full currency name, and code, with labeled FROM/TO controls and a compact Swap button. Type an amount, pick USD/JPY/EUR/GBP/ARS, swap, and convert. Argentine pesos display as `AR$` to distinguish them from USD. Pair and amount persist in `~/.local/state/omarchy/currency.json`.
