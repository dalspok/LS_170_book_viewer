require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"


before do
  @contents = File.readlines("data/toc.txt")
end

get "/" do
  @title = "Sherlock Holmes"
  erb :home
end

get "/chapters/:number" do
  number = params[:number].to_i
  chapter_name = @contents[number - 1]

  redirect "/" unless (1..@contents.size).cover? number

  @title = "Chapter #{number}: #{chapter_name}"
  @chapter = File.read("data/chp#{number}.txt")

  erb :chapter
end

get "/search" do
  @results = chapters_matching(params[:query])
  erb :search
end

not_found do
  redirect "/"
end


helpers do

  def in_paragraphs(text)
    counter = 0
    text.split("\n\n").map do |p_text|
      "<p id=#{counter += 1}>#{p_text}</p>"
    end.join
  end

  def highlight_matching(text, query)
    text.gsub(query, "<strong>#{query}</strong>")
  end

end

def each_paragraph(chapter_number)
  text = File.read("data/chp#{chapter_number}.txt")
  text.split("\n\n").each_with_index do |p_text, index|
    yield (index + 1), p_text
  end
end

# Calls the block for each chapter, passing that chapter's number, name, and
# contents.
def each_chapter
  @contents.each_with_index do |name, index|
    number = index + 1
    contents = File.read("data/chp#{number}.txt")
    yield number, name, contents
  end
end

# This method returns an Array of Hashes representing chapters that match the
# specified query. Each Hash contain values for its :name and :number keys.
def chapters_matching(query)
  results = []

  return results if !query || query.empty?

  each_chapter do |number, name, contents|
    results << {number: number, name: name} if contents.include?(query)
  end

  results.each do |element_hash|
    element_hash[:paragraphs] = paragraphs_matching(query, element_hash[:number])
  end
  results
end

def paragraphs_matching(query, chapter_number)
  results = []
  return results if !query || query.empty?
  each_paragraph(chapter_number) do |id, text|
    results << {id: id, text: text} if text.include?(query)
  end
  results
end






