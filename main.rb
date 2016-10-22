require 'open-uri'
require 'nokogiri'
require 'json'

#gets the page's phyisical HTML object, title, and the first link that it will travel to.
def goto_page url
	begin
		page=Nokogiri::HTML(open(url))
		if(page.css("#bodyContent").css('p').css('a') != nil)
			links=page.css('#bodyContent').css('p').css('a') #gets all the link tags
		else
			puts "NO VALID LINKS"
			return
		end
		nextLink="en.wikipedia.org"
		for l in links
			nextLink=l['href']
			break if valid? l['href'] #if the link is not something special, like a file or a cite note, it breaks the loop and calls the current link nextLink
		end
	rescue
		puts "ERROR PROCESSING '#{url}'"
	end
	#return the object
	return {:page => page, :title => page.css('title').text[0...page.css('title').text.index('- Wikipedia')-1], :nextLink=>"https://en.wikipedia.org#{nextLink}"}
end
#checks to see if the link has any special tags or any forbidden topics
def valid? l
	for t in ["File:", "Help:", ".ogg","#", "amigo.", "%", "/commons/", "wiktionary"]
		return false if l.include?(t)
	end
	return true
end
#saves certain paths to the file in order to reduce workload for finding the steps to philosophy
def save_path path
	json=File.read("steps.json")
	path_file=JSON.parse(json); 
	path_index=path[0] #the path will be indexed by the name of the article
	path_hash=Hash.new
	path_hash[path_index]=path
	path_file["steps"] << path_hash #append the path to the new hash
	File.open("steps.json", "w") do |f|
		f.write(path_file.to_json)
	end
end
def main url
	page=goto_page url #starts off on a random page

	existing_paths=JSON.parse(File.read("steps.json"))

	steps=[] #this will be an array of the titles the program passes through. these will be stored in a Hash, indexed by the starting page.
	if(existing_paths["steps"].find_all{|e| e.has_key?(page[:title])} != [])
		puts "Starting from #{page[:title]}, it takes #{existing_paths["steps"].find_all{|e| e.has_key?(page[:title])}[0].values[0].length} steps to get to philosophy"
	else
		puts "Cannot find existing path for #{page[:title]}. \nCrawling..."
		until page[:title] == "Philosophy"
			puts page[:title]
			steps << page[:title]
			if(steps.count(page[:title]) > 3)
				puts "#{page[:title]} has produced a loop!"
				break
			end
			page=goto_page(page[:nextLink])
		end
		steps << "Philosophy"
		save_path steps
		puts "Starting from #{steps[0]}, it takes #{steps.length()} steps to get to philosophy"
	end
end
loop do
	begin
		main "https://en.wikipedia.org/wiki/Special:Random"
	rescue Interrupt
		puts "_________Program Terminated__________"
		break
	end
end