require 'list'
require 'twilio-ruby'

describe List do
  subject(:list) { described_class.new }
#  let(:client) { double("Twilio::REST::Client", account: self, messages: self, create: true) }
  let(:twilio) { class_double("Twilio"). as_stubbed_const(:transfer_nested_constants => true) }

  describe '#view_items' do
    before(:context) { File.open("test_list.csv", "w") { |file| file.puts "Margherita, 6" } }

    it 'resets menu items' do
      expect(list).to receive(:reset_menu_items)
      list.view_items("test_list.csv")
    end

    it 'builds menu items' do
      expect(list).to receive(:build_menu_item).at_least(:once)
      list.view_items("test_list.csv")
    end

    it 'prints menu items' do
      expect(list).to receive(:print_menu)
      list.view_items("test_list.csv")
    end

    specify { expect { list.view_items("test_list.csv") }.to output(/Margherita/).to_stdout }
    specify { expect { list.view_items("test_list.csv") }.to output(/6/).to_stdout }

    after(:context) { File.delete("test_list.csv") }
  end

  describe '#select_items' do
    before(:context) do
      File.open("test_list.csv", "w") do |file|
        file.puts "Margherita, 6"
        file.puts "Trois fromages, 8"
      end
    end
    before(:example) { list.view_items("test_list.csv") }
#    before(:example) { allow(list).to receive(:send_sms).and_return(true) }
#    before(:example) { allow(twilio::REST::Client).to receive(:new).and_return(client) }

    context 'order info is invalid' do
      context 'input is incorrectly formatted' do
        it 'throws error if comma is missing' do
          expect { list.select_items('Margherita x3 $18') }.to raise_error(RuntimeError, "Input formatted incorrectly")
        end
        it 'throws error if $ is missing' do
          expect { list.select_items('Margherita x3, 18') }.to raise_error(RuntimeError, "Input formatted incorrectly")
        end
        it 'throws error if quantity is missing' do
          expect { list.select_items('Margherita, $6') }.to raise_error(RuntimeError, "Input formatted incorrectly")
        end
      end

      it 'throws error if item is not on menu' do
        expect { list.select_items('Margarita x3, $18') }.to raise_error(RuntimeError, "Item entered that is not listed on menu")
      end
      
      it 'throws error if sum cost of order is incorrect' do
        expect { list.select_items('Margherita x3, $16') }.to raise_error(RuntimeError, "Incorrect order price entered")
      end

    end

    context 'order info is valid' do
      it 'sends a text message confirming arrival time' do
        expect(list).to receive(:send_sms)
        list.select_items('Margherita x3, Trois fromages x1, $26')
      end
    end

    after(:context) { File.delete("test_list.csv") }
      
  end

end
