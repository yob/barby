require 'barby/outputter'
require 'prawn'

module Barby

  class PrawnOutputter < Outputter

    register :to_pdf, :annotate_pdf

    attr_accessor :xdim, :ydim, :x, :y, :height, :margin, :unbleed, :ean_guards


    def to_pdf(opts={})
      doc_opts = opts.delete(:document) || {}
      doc_opts[:page_size] ||= [full_width(opts), full_height(opts)]
      doc_opts[:margin]    ||= 0
      annotate_pdf(Prawn::Document.new(doc_opts), opts).render
    end


    def annotate_pdf(pdf, opts={})
      with_options opts do
        xpos, ypos = x, y
        orig_xpos = xpos

        if barcode.two_dimensional?
          boolean_groups.reverse_each do |groups|
            groups.each do |bar,amount|
              if bar
                pdf.move_to(xpos+unbleed, ypos+unbleed)
                pdf.line_to(xpos+unbleed, ypos+ydim-unbleed)
                pdf.line_to(xpos+(xdim*amount)-unbleed, ypos+ydim-unbleed)
                pdf.line_to(xpos+(xdim*amount)-unbleed, ypos+unbleed)
                pdf.line_to(xpos+unbleed, ypos+unbleed)
                pdf.fill
              end
              xpos += (xdim*amount)
            end
            xpos = orig_xpos
            ypos += ydim
          end
        else
          boolean_groups.each do |bar,amount|
            if bar
              if ean_guards && [0,1,2,45,46,47,48,49,92,93,94].include?(xpos)
	        pdf.move_to(xpos+unbleed, ypos - 2)
                pdf.line_to(xpos+unbleed, ypos+height)
                pdf.line_to(xpos+(xdim*amount)-unbleed, ypos+height)
		pdf.line_to(xpos+(xdim*amount)-unbleed, ypos - 2)
                pdf.line_to(xpos+unbleed, ypos - 2)
              else
	        pdf.move_to(xpos+unbleed, ypos)
                pdf.line_to(xpos+unbleed, ypos+height)
                pdf.line_to(xpos+(xdim*amount)-unbleed, ypos+height)
		pdf.line_to(xpos+(xdim*amount)-unbleed, ypos)
                pdf.line_to(xpos+unbleed, ypos)
              end
              pdf.fill
            end
            xpos += (xdim*amount)
          end
        end

      end

      pdf
    end


    def length
      two_dimensional? ? encoding.first.length : encoding.length
    end

    def width
      length * xdim
    end

    def height(options = {})
      two_dimensional? ? (ydim * encoding.length) : (@height || options[:height] || 50)
    end

    def full_width(options = {})
      width + (margin(options) * 2)
    end

    def full_height(options = {})
      height(options) + (margin(options) * 2)
    end

    #Margin is used for x and y if not given explicitly, effectively placing the barcode
    #<margin> points from the [left,bottom] of the page.
    #If you define x and y, there will be no margin. And if you don't define margin, it's 0.
    def margin(options = {})
      @margin || options[:margin] || 0
    end

    def x
      @x || margin
    end

    def y
      @y || margin
    end

    def xdim
      @xdim || 1
    end

    def ydim
      @ydim || xdim
    end

    #Defines an amount to reduce black bars/squares by to account for "ink bleed"
    #If xdim = 3, unbleed = 0.2, a single/width black bar will be 2.6 wide
    #For 2D, both x and y dimensions are reduced.
    def unbleed
      @unbleed || 0
    end


  private

    def page_size(xdim, height, margin)
      [width(xdim,margin), height(height,margin)]
    end


  end

end
