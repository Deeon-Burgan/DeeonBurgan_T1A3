require "tty-prompt"
require "tty-font"
require "tty-link"
require 'json'
require 'httparty'
require 'colorize'
require 'colorized_string'
require_relative './classes/entry.rb'

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

    def run
        loop do
            system 'clear'
            display_title
            input = @prompt.select("menu") do |menu|
                menu.choice 'find entry', 1
                if @beasts.count > 0
                    menu.choice 'edit entry', 2
                    menu.choice 'display random entry', 3
                    menu.choice 'list 5 random entries', 4
                    menu.choice 'list all entries', 5
                else
                    menu.choice 'edit entry', 2, disabled: '(no entries available)'
                    menu.choice 'display random entry', 3, disabled: '(no entries available)'
                    menu.choice 'list 5 random entries', 4, disabled: '(no entries available)'
                    menu.choice 'list all entries', 5, disabled: '(no entries available)'
                end
                menu.choice 'exit', 999
            end
        
            case input
            when 1
                display_search_entry
            when 2
                edit_entry_unknown
            when 3
                display_random_entry
            when 4
                list_5_entries
            when 5
                list_entries
            when 999
                exit
            end
        end
    end

    def check_available_name(name)
        @beasts.each do |beast|
            if name.upcase == beast.name.upcase
                return {"matched" => true, "beast" => beast}
            end
        end
        return {"matched" => false, "beast" => nil}
    end

    def add_entry
            name = get_string_input("Please enter the name: ").strip

            available = check_available_name(name)

            unless available["matched"] == false
                # found a match
                puts 'An existing entry with that name has been found'
                input = @prompt.select 'What would you like to do?' do |menu|
                    menu.choice 'edit existing entry', 1
                    menu.choice 'show existing entry', 2
                    menu.choice 'return to menu', 3
                end
                case input
                when 1
                    edit_entry_known(available["beast"])
                    display_entry(available["beast"])
                when 2
                    display_entry(available["beast"])
                when 3
                    return
                end
                return
            end

        description = get_string_input("Enter the description for this creature: ")
        external = ""
        tryCounter = 0
        loop do
            tryCounter += 1
            attemptsLeft = 3 - tryCounter
            puts "Attempts left: #{attemptsLeft + 1}"
            if tryCounter >= 4
                external = ''
                break
            end
            external = get_string_input("Enter an external link for more information")
            begin
                
                response = get_http_request(external)
            rescue Errno::ECONNREFUSED
                puts 'unable to pass link, please retry'
                redo
            end
            if response.code != 200
                puts "Link not valid"
                redo
            end

            break
        end
        
        add_known_entry(name, description, external)
        save_data
    end

    def get_http_request(link)
        return HTTParty.get(link)
    end


    def add_known_entry(a_name, a_description, a_external)
        ne = Entry.new(a_name, a_description, a_external)
        @beasts << ne 
        ne
    end

    def get_confirmation(thingToConfirm)
        @prompt.yes?("Would you like to #{thingToConfirm}".colorize(:green))
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

    def find_matching_entries
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
            # puts beast.name
            matches = 0
            tags.each do |tag| 
                if tag.upcase == beast.name.upcase
                    matches += 1
                end
                descriptionArray = beast.description.split(" ")
                descriptionArray.each do |word| 
                    if tag.upcase == word.upcase
                        matches += 0.1
                    end
                end
            end
            if matches != 0
                matchesList << {"beast" => beast, "index" => index}
            end
        end
        return matchesList
    end

    def find_entry
        matchesList = find_matching_entries
        if matchesList.count <= 0
            return nil
        else
            input = @prompt.select 'matched entries' do |menu|
                matchesList.each do |match|
                    menu.choice match["beast"].name, match["index"]
                end

                menu.choice 'Create new entry?', 1000
            end
            case input
            when 1000
                return nil
            else
                return @beasts[input]
            end
        end
    end

    def display_entry(entry)
        loop do
            clear_sys
            puts "Beast name: #{entry.name}"
            puts entry.description
            entry.external == '' ? (puts '') : (puts TTY::Link.link_to("#{entry.name} in more detail".colorize(:blue), entry.external))
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
        # puts maxIndex
        @beasts = @beasts.sort_by {|beast| beast.name.upcase}

        loop do
            input = @prompt.select("", per_page: 7) do |menu|
                for i in 0..4 do 
                    arrI = i + (index * 5)
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
    rescue Errno::ENOENT
        File.open(@file_path, 'w+')
        File.write(@file_path, [])
        retry
    end

end