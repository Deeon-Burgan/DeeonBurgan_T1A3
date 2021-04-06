require 'tco'
require 'rmagick'

class Timage
    # taken from https://radek.io/2015/06/29/catpix/
    def self.DrawImage(img_path)
        img = Magick::Image::read(img_path).first
        puts img
        gets
        img.each_pixel do |pixel, col, row|
            c = [pixel.red, pixel.green, pixel.blue].map { |v| 256 * (v / 65535.0) }
            print("  ".bg c)
            puts if col >= img.columns - 1
        end
    end
end