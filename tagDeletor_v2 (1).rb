require 'nationbuilder'
require 'rubygems'
require 'csv'
require 'erb'
include ERB::Util
require 'thread/pool'

puts ''
puts ''
puts "******** Let\'s Get Ready To Remove Some Tags ********"
puts "This program will ask you some questions about the nation for tag removal."
puts "Then, it's going to remove all of the tags listed in your provided csv from the nation."

sleep 0.5

puts "please enter your nation slug."
slug = gets
slug = slug.chomp 
puts ''
puts "please enter the API key for that nation (you can copy and paste)."
api_token = gets
api_token = api_token.chomp
puts ''

puts "Please Enter The Filename of csv of tags that will be removed."
puts "This File Must Be Located in the same directory as this Ruby script."
puts "( example: beajohnsonTagsToRemove.csv )"
puts ""



pathname = __dir__.to_s + "/"
file = gets
file = file.chomp 

fileandpath = pathname + file

tagsToRemove = []

puts "FilePath is #{fileandpath}"

CSV.foreach(fileandpath) do |row|
	puts row[0]
    unless row[0].include? "/" || row[0] == nil
	   tagsToRemove << row[0]
    end
end

puts "Tags Which Will Be Removed:"
puts ""
puts tagsToRemove

client = NationBuilder::Client.new(slug, api_token, retries: 8)

def tagsRemover(client,signup_id,tagToRemove)
    client.call(:people, :tag_removal, id: signup_id, tag:tagToRemove)
end

def taggedProfilesFinder_And_Cleaner(client, tagAsWritten)
	tagToCheck = url_encode(tagAsWritten)
    #puts "TAG TO CHECK URL-ized"
    #puts tagToCheck 
	peopleTagged = client.call(:people_tags, :people, tag: tagToCheck, limit:100)
	paginated = NationBuilder::Paginator.new(client, peopleTagged)
	peopleIdsTagged = []
	while paginated.next?
	  response = paginated.body
	  response['results'].each do |result|
	    peopleIdsTagged.push([result['id']])
	  end
	  paginated = paginated.next
	end
	response = paginated.body
	response['results'].each do |result|
	    peopleIdsTagged.push([result['id']])
	end
    peopleIdsTagged.each do |signup_id|
            tagsRemover(client,signup_id[0],tagToCheck)
    end
end

date = Time.now.to_s
puts "**********"
puts ""
puts "Started At: #{date}" 
puts ""
puts "This can take a 10 minutes to over an hour to complete if"
puts "Your nation contains a lot of profiles"
puts "tagged with the tags we\'re going to delete."
puts ""
sleep 2.5
puts ""
puts ""
puts "Do Not Let Your Computer Go To Sleep."
puts "Maintain An Internet Connection."
puts "Please make sure your computer is plugged in."
puts ""
puts ""
sleep 1.5
puts "Take your vitamins."
puts "Get 8 hours of sleep."
puts "Make sure you drink enough water."
puts "and take time out of each day for yourself."
puts ""
sleep 1.5
puts "**WORKING**"
masterListForRemoval = []

pool = Thread.pool(7)
tagsToRemove.each do |tag|
    pool.process do
        taggedProfilesFinder_And_Cleaner(client, tag)
    end
end
pool.shutdown

puts "Started At: #{date}" 
date2 = Time.now.to_s
puts "Ended At: #{date2}" 
puts "Please wait several hours (possibly a full day)"
puts "and then go to #{slug}.nationbuilder.com/admin/signup_tags"
puts "and click Actions -> Delete unused tags."
puts ""
puts "Thank you and have a nice day! 🐝"
