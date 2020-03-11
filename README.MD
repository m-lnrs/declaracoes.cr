# Declarações

The emission of statements is a commun task at Faculdade de Tecnologia de Ourinhos. I wrote this program in order to standardize the emission of this type of documents by the institution, as well as the generation of the respective register number file for the institution's registration book. This program is also responsible to reduce the printing of physical files by digitizing all participation statements from events organized by the Faculdade de Tecnologia de Ourinhos.

I rewrite this program in Crystal (the original version is writen in Python) because I really like the ideas that surrounds the language, so I thought it was a way to get in touch with the cool syntaxe and concepts that Crystal inherits from Ruby.

## Installation

- [Install crystal programming language](https://crystal-lang.org/install/).
- It is also necessary to install chromium browser in order to generate the PDFs with headless mode.
- Then... install the dependencies with `shards install`

## Usage

- Run the program with `crystal run src/declaracoes`
- Once it is running, access: http://localhost:3000/declaracoes/emissao

## Contributing

1. Fork it (<https://github.com/m-lib/declaracoes.rc/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Include some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [m-lib](https://github.com/m-lib) - creator and maintainer
