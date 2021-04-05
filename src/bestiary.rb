require "tty-prompt"
require "tty-font"
require "tty-link"
require 'json'

class Bestiary

    attr_accessor :beasts

    def initialize(file_path)
        @beasts = []
        @prompt = TTY::Prompt.new
        @font = TTY::Font.new(:starwars)
        @pastel = Pastel.new
        @file_path = file_path
        load_data
    end

    def display_title
        puts @pastel.yellow(@font.write("BEASTS"))
    end

    def get_string_input(output_request)
        puts output_request
        gets.chomp
    end

    def add_entry
        name = get_string_input("Please enter the name: ")
        description = get_string_input("Enter the description for this creature: ")
        newEntry = {name: name, description: description}
        @beasts << newEntry
        save_data
    end

    def get_confirmation(thingToConfirm)
        # puts confirmationText + thingToConfirm
        @prompt.yes?("Are you sure you'd like to " + thingToConfirm)
    end

    def return_to_menu
        case @prompt.yes?("Would you like to return to menu?")
        when false 
            on_exit
        end
    end

    def cancelled_option
        puts "You have chosen to cancel your current option"
    end

    def edit_entry_known(entry)
        b1 = get_confirmation("edit this entry? #{entry}")
        case b1
        when false
            puts "is false"
            cancelled_option
            return
        end

        newDescription = get_string_input("Please write a new description for this entry")
        # sanity check input
        if newDescription == ""
            return nil
        end

        # if input is good set the entry
        entry[:description] = newDescription
    end

    def edit_entry_unknown
        entry = find_entry()
        # sanity check entry
        edit_entry_known(entry)
    end

    def find_entry
        searchTags = get_string_input("What are you looking for?")
        tags = searchTags.split(", ")

        matchesList = []
        matchesWinner = nil
        matchesCount = 0

        @beasts.each do |beast| 
            matches = 0
            tags.each do |tag| 
                if tag.upcase == beast[:name].upcase
                    matches += 1
                end

                descriptionArray = beast[:description].split(" ")
                descriptionArray.each do |word| 
                    if tag.upcase == word.upcase
                        matches += 0.1
                    end
                end
            end

            if matches >= matchesCount
                matchesWinner = beast
                matchesCount = matches
            end
        end

        return matchesWinner
    end

    def display_entry(entry)
        puts "Name: #{entry[:name]}"
        puts entry[:description]
        puts
        return_to_menu
    end

    def display_random_entry
        display_entry(@beasts[rand(0...@beasts.count)])
    end

    def list_5_entries
        randomEntries = @beasts.sample(5)
        input = @prompt.select("Pick a beast") do |menu|
            randomEntries.each_with_index do |entries,index|
                menu.choice entries[:name], index
            end
        end

        display_entry(randomEntries[input])
    end

    def list_entries
        index = 0
        maxIndex = (@beasts.count.to_f / 5.0).ceil
        puts maxIndex

        loop do
            input = @prompt.select("") do |menu|
                for i in 0..4 do 
                    arrI = i + (index * 5)
                    menu.choice @beasts[arrI][:name], index + 1 if arrI < @beasts.count
                end
                menu.choice "Next", 6 if index + 1 != maxIndex
                menu.choice "Previous", 7 if index != 0
                menu.choice "Return to menu", 8
            end

            case input
            when 6 
                index += 1
            when 7 
                index -= 1
            when 8 
                return
            else
                display_entry(@beasts[index])
                return
            end
        end
    end


    def on_exit()
        save_data
        exit
    end

    def save_data()
        File.write(@file_path, @beasts.to_json)
    end

    def load_data()
        data = JSON.parse(File.read(@file_path))
        @beasts = data.map do |beast| 
            beast.transform_keys(&:to_sym)
        end
    rescue Errno::ENOENT
        File.open(@file_path, 'w+')
        File.write(@file_path, [])
        retry
    end

end

a = Bestiary.new('./data/saved-data.json')
prompt = TTY::Prompt.new

loop do
    system 'clear'
    a.display_title
    input = prompt.select("menu") do |menu|
        menu.choice 'add new entry', 1
        menu.choice 'edit entry', 2
        menu.choice 'display random entry', 3
        menu.choice 'display 5 random entries', 4
        menu.choice 'list all entries', 5
        menu.choice 'exit', 999
    end

    case input
    when 1
        a.add_entry
    when 2
        a.edit_entry_unknown
    when 3
        a.display_random_entry
    when 4
        a.list_5_entries
    when 5
        a.list_entries
    when 999
        exit
    end
end

a.edit_entry_unknown