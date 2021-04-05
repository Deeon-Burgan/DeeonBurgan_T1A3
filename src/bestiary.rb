require "tty-prompt"
require "tty-font"
require "tty-link"
require 'json'
require './classes/entry.rb'

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
        # loop do 
            name = get_string_input("Please enter the name: ")

            nameAvail = true
            beastI = nil
            @beasts.each do |beast|
                if name.upcase == beast.name.upcase
                    nameAvail = false
                    beastI = beast
                end
            end

            unless nameAvail
                # found a match
                puts 'An existing entry with that name has been found'
                input = @prompt.select 'What would you like to do?' do |menu|
                    menu.choice 'edit existing entry', 1
                    menu.choice 'show existing entry', 2
                    menu.choice 'return to menu', 3
                end
                case input
                when 1
                    edit_entry_known(beastI)
                    display_entry(beastI)
                when 2
                    display_entry(beastI)
                when 3
                    return
                end
                # case get_confirmation("edit the existing entry?")
                # when true
                #     edit_entry_known(beastI)
                #     display_entry(beastI)
                # end
                return
            end

        #     break
        # end
        description = get_string_input("Enter the description for this creature: ")
        external = get_string_input("Enter an external link for more information")
        ne = Entry.new(name, description, external)
        @beasts << ne 
        # newEntry = {name: name, description: description}
        # @beasts << newEntry
        save_data
        ne
    end

    def get_confirmation(thingToConfirm)
        # puts confirmationText + thingToConfirm
        @prompt.yes?("Would you like to " + thingToConfirm)
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
        b1 = get_confirmation("edit this entry? #{entry.name}")
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
        entry.description = newDescription
        # entry[:description] = newDescription
        save_data
    end

    def edit_entry_unknown
        entry = find_entry()
        # sanity check entry
        begin
        edit_entry_known(entry)
        rescue StandardError
            puts "Wasn't able to find matching entry, bringing you back to menu"
            gets
            return
        end
        display_entry(entry)
    end

    def find_entry
        searchTags = ''
        tags = []

        loop do
            clear_sys
            searchTags = get_string_input("What are you looking for?")
            tags = searchTags.split(" ")
            if tags.count <= 0
                puts "No search query found"
                gets
                redo
            end

            break
        end

        matchesList = []
        matchesWinner = nil
        matchesCount = 0

        @beasts.each_with_index do |beast, index| 
            matches = 0
            tags.each do |tag| 
                if tag.upcase == beast.name.upcase
                # if tag.upcase == beast[:name].upcase
                    matches += 1
                end

                descriptionArray = beast.description.split(" ")
                # descriptionArray = beast[:description].split(" ")
                descriptionArray.each do |word| 
                    if tag.upcase == word.upcase
                        matches += 0.1
                    end
                end
            end

            # if matches >= matchesCount
            #     matchesWinner = beast
            #     matchesCount = matches
            # end
            if matches != 0
                matchesList << {"beast" => beast, "index" => index}
            end
        end

        if matchesList.count <= 0
            return nil
        else
            input = @prompt.select 'matched entries' do |menu|
                matchesList.each do |match|
                    menu.choice match["beast"].name, match["index"]
                end
            end

            return @beasts[input]
        end

        # if matchesCount == 0
        #     # case get_confirmation("add a new entry?")
        #     # when true
        #     #     return add_entry
        #     # when false
        #     #     return nil
        #     # end
        #     return nil
        # end
        # return matchesWinner
    end

    def display_entry(entry)
        loop do
            clear_sys
            puts "Beast name: #{entry.name}"
            puts entry.description
            puts entry.external
            # puts "Name: #{entry[:name]}"
            # puts entry[:description]
            # puts
            # return_to_menu
            display_entry_menu ? edit_entry_known(entry) : return
        end
    end

    def display_entry_menu
        input = @prompt.select("What would you like to do?") do |menu|
            menu.choice "Edit entry", 1
            menu.choice "Return to menu", 2
        end

        case input
        when 1
            return true
        when 2
            return false
        end
    end

    def display_random_entry
        display_entry(@beasts[rand(0...@beasts.count)])
    end

    def list_5_entries
        randomEntries = @beasts.sample(5)
        input = @prompt.select("Pick a beast") do |menu|
            randomEntries.each_with_index do |entries,index|
                # menu.choice entries[:name], index
                menu.choice entries.name, index
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
                    # menu.choice @beasts[arrI][:name], arrI if arrI < @beasts.count
                    menu.choice @beasts[arrI].name, arrI if arrI < @beasts.count
                end
                menu.choice "Next", 100 if index + 1 != maxIndex
                menu.choice "Previous", 101 if index != 0
                menu.choice "Return to menu", 102
            end

            case input
            when 100 
                index += 1
            when 101 
                index -= 1
            when 102 
                return
            else
                display_entry(@beasts[input])
                return
            end
        end
    end

    def display_search_entry
        # add rescue for nil entry
        entry = find_entry
        # entry != nil ? display_entry(entry) : return
        if entry == nil
            case get_confirmation("add a new entry?")
            when true 
                entry = add_entry
            end
        end 

        # rescue for if entry is nil
        # could technically just do a ternary, but i like style
        begin
        display_entry(entry)
        rescue StandardError
            return
        end
        # display_entry(find_entry)
    end


    def clear_sys
        system 'clear'
        display_title
    end

    def on_exit()
        save_data
        exit
    end

    def save_data()
        File.write(@file_path, @beasts.to_json)
    end

    def load_data()
        data = JSON.parse(File.read(@file_path), create_additions: true)
        @beasts = data
        puts @beasts
        gets
        # @beasts = data.map do |beast| 
        #     beast.transform_keys(&:to_sym)
        # end
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
        menu.choice 'find entry', 1
        menu.choice 'edit entry', 2
        menu.choice 'display random entry', 3
        menu.choice 'list 5 random entries', 4
        menu.choice 'list all entries', 5
        menu.choice 'exit', 999
    end

    case input
    when 1
        a.display_search_entry
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