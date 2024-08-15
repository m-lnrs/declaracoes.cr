require "http/client"
require "kemal"
require "csv"

# Some classes to use with from_json
# before 1.0.0
#class Pessoa
#	JSON.mapping(
#		nome: String
#	)
#end
class Pessoa
	include JSON::Serializable
	@nome: String
end

# before 1.0.0
#class Atividade
#	JSON.mapping(
#		nome: String
#	)
#end
class Atividade
	include JSON::Serializable
	@nome: String
end

# before 1.0.0
#class Inscricao
#	JSON.mapping(
#		atividade: {type: Atividade},
#		codigo: Int64
#	)
#end
class Inscricao
	include JSON::Serializable
	@atividade: Atividade
	@codigo: Int64
end

# before 1.0.0
#class Search
#	JSON.mapping(
#		pessoa: {type: Pessoa},
#		inscricoes: {type: Array(Inscricao), nilable: true},
#	)
#end
class Search
	include JSON::Serializable
	@pessoa: Pessoa
	@inscricoes: Array(Inscricao)
end

# Include a new function inside Time struct (metaprogramming)
struct Time
	def month_name
		month_names = ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"]
		return month_names[month - 1]
	end
end

#static_headers do |response, filepath, filestat|
#	response.headers.add("Access-Control-Allow-Origin", "*")
#	response.headers.add("Content-Size", filestat.size.to_s)
#end

get "/" do |env|
	env.redirect "/declaracoes"
end

get "/declaracoes" do
	render "src/views/index.ecr", "src/views/layouts/template.ecr"
end

post "/declaracoes" do |env|
	env.redirect "/declaracoes/buscar/inscricoes/pessoa/" + env.params.body["CPF"]
end

post "/declaracoes/emissao/declaracao" do |env|
	# Initialize the declaration array in the case user do not pass a csv file
	declarations = Array(String).new
	declarations << env.params.body["text"]

	# Check if the form has the "file" attribute
	if env.params.files.has_key? "file"
		# Check if the "file" attribute was submited by the user
		filename = env.params.files["file"].filename
		if filename != ""
			begin
				csv_header = env.params.body["csv_header"] == "true"
				csv = CSV.new(env.params.files["file"].tempfile, headers = csv_header)

				# If the user pass a file, then it is necessary to clean the declarations array
				declarations.clear

				csv.each do |line|
					column = 0
					text = env.params.body["text"]
					while column < line.row.size
						text = text.gsub("{#{column}}", line[column])
						column = column + 1
					end
					declarations << text
				end
			rescue # If anything goes wrong here...
				# Remove all temporary files created during the form submition
				remove_temporary_files env
			end

		end
	end

	# Remove all temporary files created during the form submition
	remove_temporary_files env

	header = env.params.body["header"]
	emission = env.params.body["number"]
	orientation = env.params.body["orientation"]

	send_PDF env, render "src/views/declarations.ecr"
end

post "/declaracoes/emissao/registro" do |env|
	names = Array(String).new

	# Check if the form has the "file" attribute
	if env.params.files.has_key? "file"
		# Check if the "file" attribute was submited by the user
		filename = env.params.files["file"].filename
		if filename != ""
			begin
				csv_header = env.params.body["csv_header"] == "true"

				csv = CSV.new(env.params.files["file"].tempfile, headers = csv_header)

	#			begin # Check if the csv column number passed by the user is not greater than the csv headers size
	#				csv_column = env.params.body["column"]
	#				max_column = csv.headers.size - 1
	#				if csv_column.to_i > max_column
	#					halt env, status_code: 500, response: "Max column number possible is #{max_column} bro!"
	#				end
	#			rescue CSV::Error # Only if the csv has a Header...
	#				halt env, status_code: 500, response: "You told me that your csv file has no headers bro!"
	#			end

				csv_column = env.params.body["column"]

				begin
					if csv_column.to_i - 1 < 0
						halt env, status_code: 500, response: "The min csv column possible is 1 bro!"
					end
				rescue
					halt env, status_code: 500, response: "#{csv_column} is not a number bro!"
				end

				row_count = 1
				csv.each do |line|
					begin
						names << line[csv_column.to_i - 1]
						row_count = row_count + 1
					rescue IndexError # In case user pass a csv column greater than the row size
						halt env, status_code: 500, response: "Max column number possible for row #{row_count} of your csv file is #{line.row.size} bro!"
					end
				end
			rescue # If anything goes wrong here...
				# Remove all temporary files created during the form submition
				remove_temporary_files env
			end

		end
	end

	title = env.params.body["title"]
	emission = env.params.body["number"]

	# Remove all temporary files create during the form submition
	remove_temporary_files env

	send_PDF env, render "src/views/register.ecr"
end

get "/declaracoes/emissao" do
	time = Time.local
	text = <<-STRING
		<br>

		<h1>
			<p align='center'><strong><em>DECLARAÇÃO</em></strong></p>
		</h1>

		<br>

		<p align='justify'>A Faculdade de Tecnologia de Ourinhos declara, para os devidos fins...</p>

		<br>

		<p align='right'>Ourinhos, #{time.day} de #{time.month_name} de #{time.year}.</p>

		<br><br><br>

		<p align='center'><strong>Responsável</strong>

		<br>

		<small><em>Cargo na Faculdade de Tecnologia de Ourinhos</em></small></p>
	STRING

	render "src/views/emission.ecr", "src/views/layouts/template.ecr"
end

error 500 do
	render "src/views/500.ecr", "src/views/layouts/template.ecr"
end

get "/declaracoes/buscar/inscricoes/pessoa/:cpf" do |env|
	cpf = env.params.url["cpf"]
	response = HTTP::Client.get "http://localhost:8080/academico/pessoa/#{cpf}/inscricoes"

	if response.status_code == 404
		halt env, status_code: 404, response: "I can not find any person with this CPF bro!"
	end

	json = JSON.parse(response.body)
	render "src/views/inscriptions.ecr", "src/views/layouts/template.ecr"
end

get "/declaracoes/inscricao/:code" do |env|
	code = env.params.url["code"]
	response = HTTP::Client.get "http://localhost:8080/academico/inscricao/buscar/#{code}"

	if response.status_code == 404
		halt env, status_code: 404, response: "It seems that this is not a genuine declaration bro!"
	end

	json = JSON.parse(response.body)

	text = <<-STRING
		<p class="text-28" align="center">
			<strong><em>CERTIFICADO</em></strong>
		</p>

		<p align="justify">
			A Faculdade de Tecnologia de Ourinhos certifica
			que <strong>#{json["inscricao"]["pessoa"]["nome"]}</strong>,
			participou #{json["inscricao"]["atividade"]["tipo"]}: <strong>"#{json["inscricao"]["atividade"]["nome"]}"</strong> #{json["inscricao"]["atividade"]["realizacao"]}
			com carga horária total de #{json["inscricao"]["atividade"]["cargaHoraria"]} horas.
		</p>

		<p align="right">
			Ourinhos, #{json["inscricao"]["emissao"]}.
		</p>

		<p align="center">
			<img src="http://localhost:8080/academico/resources/imagens/lia.svg">
		</p>
	STRING

	declarations = Array(String).new
	declarations << text
	orientation = "1"  # landscape
	header = "1"       # aways display header logo image

	emission = "Este documento foi emitido pelo sistema de controle de declarações da Faculdade de Tecnologia de Ourinhos e pode ser autenticado pela URL: <span class='nowrap'>https://www.fatecourinhos.edu.br/declaracoes/inscricao/#{code}</span>"

	send_PDF env, render "src/views/declarations.ecr"
end

def remove_temporary_files(env : HTTP::Server::Context)
	env.params.files.each_key do |key|
		env.params.files[key].tempfile.delete
	end
end

def send_PDF(env : HTTP::Server::Context, content : String)
	# Create a temporary file to render the HTML on it
	# This way it is possible to pass this temporary file to chrome render out the PDF
	source = File.tempfile("SOURCE.HTML") do |file|
		file.print(content)
	end

	#https://download-chromium.appspot.com
	#parameters = ["--headless", "--disable-gpu", "--run-all-compositor-stages-before-draw", "--virtual-time-budget=10000", "--print-to-pdf-no-header", "--print-to-pdf", "--no-margins", "#{source.path}"]
	#process = Process.new("chromium-browser", parameters, output: Process::Redirect::Pipe)
	parameters = ["#{source.path}", "OUTPUT.PDF"]
	process = Process.new("weasyprint", parameters, output: Process::Redirect::Pipe)

	process.wait.success?

	# Delete the temporary file used to render the declaration
	source.delete

	# Send the generated PDF to the user
	send_file env, "OUTPUT.PDF"

	# Delete the PDF after send it to the user
	`rm OUTPUT.PDF`
end

Kemal.run ARGV[0]?.try &.to_i?
