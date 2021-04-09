require_relative '../bestiary.rb'
# require_relative "..classes/entry.rb"
require 'tty-prompt'
require 'tty/prompt/test'

ARGV.clear

RSpec.describe Bestiary do
    subject(:bestiary) do
        described_class.new('../data/saved-data.json')
    end

    describe 'InputRequirements' do
        let(:prompt){TTY::Prompt::Test.new}

        before do
            prompt.on :keypress do |e|
                prompt.trigger :keyup if e.value == 'k'
                prompt.trigger :keydown if e.value == 'j'
            end
        end

        # write case to test add entry
        # 1st test
        # it "should add a valid entry" do
        #     name = "dog"
        #     description = "fluffy boy"
        #     external = "http://google.com"
            

        #     expectedClass = Entry.new name, description, external
        #     expect(bestiary.beasts[0]).to be expectedClass
        # end
            # check for valid entry
        # 2nd test 
            # check for when an entry is already valid
    end

    describe 'Adding Entry' do 
        # before do 
        #     expectedClass.add_known_entry("Lion", "Big roar", "https://google.com")
        # end

        it 'should add entry to list' do
            expectedClass = Entry.new "Sweater", "isn't animal but clothing", ""
            bestiary.add_known_entry("Sweater", "isn't animal but clothing", "")

            
            expect(bestiary.beasts.last).to eq expectedClass
        end

        before do 
            name = "John"
            description = "Bird"
            external = "http://google.com"
            bestiary.add_known_entry(name, description, external)
        end

        it 'should tell us a match has been found' do
            name = "John"
            expectedEntry = Entry.new("John", "Bird", "http://google.com")

            expect((bestiary.check_available_name(name)["matched"]) == true).to eq true
        end
    end

    describe 'Finding entries' do
        before do
            bestiary.add_known_entry("Sweater", "isn't animal but clothing", "")
            bestiary.add_known_entry("Weather", "isn't animal but status of global temperature and world state", "")
            bestiary.add_known_entry("Clothing", "is many things, including Sweater", "")
        end

        let(:input) {StringIO.new("Sweater")}
        it 'should get list of all matching entries' do
            $stdin = input
            expectedEntry1 = Entry.new("Sweater", "isn't animal but clothing", "")
            expectedEntry2 = Entry.new("Clothing", "is many things, including Sweater", "")
            matches = bestiary.find_matching_entries
            puts matches
            gets

            expect(matches[0]["beast"] == expectedEntry1 && matches[1]["beast"] == expectedEntry2).to eq true
        end

        let(:input) {StringIO.new('blah')}
        it 'should return emtpy array if no matches are found' do
            $stdin = input
            matches = bestiary.find_matching_entries
            expect(matches.count).to be 0
        end
    end
end
