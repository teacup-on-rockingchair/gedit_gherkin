startString = String.new('<?xml version="1.0" encoding="UTF-8"?>
<!--

 Author: strandjata@gmail.com
 As a basis for the lang spec I used the ruby.lang shipped with my Ubuntu by 
 Archit Baweja <bighead@users.sourceforge.net>
 Michael Witrant <mike@lepton.fr>
 Gabriel Bauman <gbauman@gmail.com>

 This library is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

-->
<language id="gherkin" _name="gherkin" version="2.0" _section="Scripts">
  <metadata>
    <property name="mimetypes">text/x-feature</property>
    <property name="globs">*.feature</property>
  </metadata>

  <styles>
    <style id="escape"               _name="Escaped Character"     map-to="def:special-char"/>
    <style id="keyword"              _name="Keyword"               map-to="def:keyword"/>
    <style id="string"               _name="String"                map-to="def:string"/>
    <style id="symbol"               _name="Symbol"                map-to="def:string"/>
    <style id="special-variable"     _name="Special Variable"      map-to="def:identifier"/>
    <style id="variable"             _name="Variable"              map-to="def:identifier"/>
    <style id="regex"                _name="Regular Expression"    map-to="def:identifier"/>
    <style id="blocks"          _name="Block Name"            map-to="def:type"/>

  </styles>

  <definitions>

    <context id="escape" style-ref="escape">
      <match>\\\\((0-7){3}|(x[a-fA-F0-9]{2})|(c\S)|([CM]-\S)|(M-C-\S)|.)</match>
    </context>

    <context id="global-variables" style-ref="variable">
      <match>\$[a-zA-Z_][a-zA-Z0-9_]*</match>
    </context>

    <context id="class-variables" style-ref="variable">
      <match>@@[a-zA-Z_][a-zA-Z0-9_]*</match>
    </context>

    <context id="instance-variables" style-ref="variable">
      <match>@[a-zA-Z_][a-zA-Z0-9_]*</match>
    </context>

    <context id="symbols" style-ref="symbol">
      <match>(?&lt;!:):[a-zA-Z0-9_]+</match>
    </context>

    <context id="regexp-variables" style-ref="regex">
      <match>\$[1-9][0-9]*</match>
    </context>

    <!-- in double quotes and backticks -->
    <context id="simple-interpolation">
      <start>#(?=[@$])</start> <!-- need assertion to not highlight single # -->
      <end></end>
      <include>
        <context ref="class-variables"/>
        <context ref="instance-variables"/>
        <context ref="global-variables"/>
      </include>
    </context>


    <context id="complex-interpolation">
      <start>#{</start>
      <end>}</end>
      <include>
        <context ref="gherkin:*"/>
      </include>
    </context>


    <context id="double-quoted-string" style-ref="string" class="string" class-disabled="no-spell-check">
      <start>"</start>
      <end>"</end>
      <include>
        <context ref="escape"/>
        <context ref="def:line-continue"/>
        <context ref="complex-interpolation"/>
        <context ref="simple-interpolation"/>
      </include>
    </context>

')


endString = '
  
  
        
    <context id="gherkin" class="no-spell-check">
        <include>
            <context ref="keywords"/>
            <context ref="double-quoted-string" />
            <context id="block-ids" style-ref="blocks">
                <match>\%{start-scenario}</match>
            </context>
            <context id="narrative" style-ref="blocks">
                    <start>\%{start-of-narrative}</start>
                    <end>\%{start-scenario}</end>
            </context>

        </include>
    </context>

  </definitions>
</language>'

def cucumber_i18n_languages()
    `cucumber --i18n help`
end


def cucumber_i18n_help(lang)
    `cucumber --i18n #{lang} --help`
end

class GherkinCollection

    def initialize(header,entry_prefix,entry_suffix,footer)
        @blockIdsString = String.new
        @header_string = header
        @entry_prefix = entry_prefix
        @entry_suffix = entry_suffix
        @footer = footer
        @blockIdsString.concat(@header_string)
    end

    def addLanguageBlockId(lang)
       @blockIdsString.concat(@entry_prefix + lang + @entry_suffix) 
    end

    def finish
         @blockIdsString.concat(@footer)
    end

    def output_result
        puts @blockIdsString
    end
end

class GherkinConcatenation < GherkinCollection

    def finish
        @blockIdsString = @blockIdsString.chop
        @blockIdsString.concat(@footer)
    end
end


#
# Parent class for keywords and block ids
#
class GherkinWords
    def initialize(lang,context_name,*styleref)
        @lang = lang
        @gKeywordsArray = Array.new
        @gherkinWordsString = String.new
        @styleref = styleref[0]
        @context_name = context_name
    end
    
    def classify(key)
    end

    def gherkinWordsExtract(mapWords)
        gKeywordsArray = Array.new
        arrayIndex = 0
        mapWords.each do |key,value|
            if classify(key)
                valuesArray = Array.new
    #            puts "#{key},#{value}"
                valuesArray = value.split(',')
                valuesArray.each do |val|
                    @gKeywordsArray[arrayIndex] = val.lstrip.rstrip
                    arrayIndex = arrayIndex+1
                end
            end
        end
        gKeywordsArray
    end

    def buildGherkinwordConcatenation
    end

    def output_xml
    end
end

#
# Keywords Class
#
class GherkinKeyWords < GherkinWords

    # where keywords are
    def classify(key)
         keywords = ["given (code)","when (code)","then (code)","and (code)","but (code)"]
        keywords.member?(key)
    end

    def buildGherkinwordConcatenation
        arrayIndex = 0
        @gKeywordsArray.each do |val|
    #        puts val
            @gherkinWordsString = @gherkinWordsString + val+' |'
        end
        @gherkinWordsString = @gherkinWordsString.chop
    end

    def output_xml
        buildGherkinwordConcatenation
        puts  "\n\t\<context id\=\"#{@context_name}-#{@lang}\" style-ref\=\"#{@styleref}\"\>\n\t\t\<match\>\^\[\\t\\s\]\*\
\(#{@gherkinWordsString})\<\/match\>\n\t\<\/context\>"
    end
end


#
# BlockWords Class
#
class GherkinBlockWords < GherkinWords

    # where block ids are
    def classify(key)
        blockwords = ["examples","background","scenario","scenario_outline"]
        blockwords.member?(key)
    end

    def buildGherkinwordConcatenation
        arrayIndex = 0
        @gKeywordsArray.each do |val|
    #        puts val
            @gherkinWordsString = @gherkinWordsString + val+'|'
        end
        @gherkinWordsString = @gherkinWordsString.chop
    end
    
    def output_xml
        buildGherkinwordConcatenation
        puts  '<define-regex id="'+@context_name+'-'+@lang+'">^[\t\s]*('+@gherkinWordsString+'):</define-regex>'  

#"\n\t\<context id\=\"#{@context_name}-#{@lang}\" style-ref\=\"#{@styleref}\"\>\n\t\t\<match\>\^\[\\t\\s\]\*\
#\(#{@gherkinWordsString})\:\<\/match\>\n\t\<\/context\>"
    end

end


#
# BlockWords Class
#
class GherkinNarrativeWords < GherkinWords

    # where block ids are
    def classify(key)
        blockwords = ["feature"]
        blockwords.member?(key)
    end

    def buildGherkinwordConcatenation
        arrayIndex = 0
        @gKeywordsArray.each do |val|
    #        puts val
            @gherkinWordsString = @gherkinWordsString + val+'|'
        end
        @gherkinWordsString = @gherkinWordsString.chop
    end
    
    def output_xml
        buildGherkinwordConcatenation
        puts  '<define-regex id="'+@context_name+'-'+@lang+'">^[\t\s]*('+@gherkinWordsString+'):</define-regex>'

 # "\n\t\<context id\=\"#{@context_name}-#{@lang}\" style-ref\=\"#{@styleref}\"\>\n\t\t\<match\>\^\[\\t\\s\]\*\
#\(#{@gherkinWordsString})\:\<\/match\>\n\t\<\/context\>"
    end

end



def extract_supported_languages
    output = cucumber_i18n_languages
    lines = output.split(/\n/)
    mapLanguages = Hash.new
    lines.each do |line|
        space,title,value,finish=line.chomp.split('|')
        title=title.lstrip.rstrip
        value=value.gsub(/\"/,'').lstrip.rstrip
        mapLanguages[title] = value
    end

    mapLanguages
end

def process_language_table(lang)

    output = cucumber_i18n_help(lang)
    lines = output.split(/\n/)
    mapGherkin = Hash.new
    lines.each do |line|
        space,title,value,finish=line.chomp.split('|')
        title=title.lstrip.rstrip
         value=value.gsub(/\"/,'')
        mapGherkin[title] = value
    end

    mapGherkin
end



if $0 == __FILE__

    mapLanguages = extract_supported_languages

    blockIdCollection = GherkinConcatenation.new('<define-regex id="start-scenario" extended="true">(',\
    "\n\t\t\\\%\{start\-of\-scenario\-",'}|',"\n\)\<\/define\-regex\>")

    keywordsCollection = GherkinCollection.new(	"\<context id\=\"keywords\"\>\n\t\t\<include\>",\
    "\n\t\t\t\<context ref\=\"keywords\-",'"/>',"\n\t\t\<\/include\>\n\t\<\/context\>")

    narrativeCollection = GherkinConcatenation.new('<define-regex id="start-of-narrative" extended="true">(',\
    "\n\t\t\\\%\{start\-of\-narrative\-",'}|',"\n\t\)\<\/define\-regex\>")
    
    puts startString

    mapLanguages.each do |lang,description| 


        blocks = GherkinBlockWords.new(lang,'start-of-scenario')
        blocks.gherkinWordsExtract(process_language_table(lang))
        blocks.output_xml


        words = GherkinKeyWords.new(lang,"keywords","keyword")
        words.gherkinWordsExtract(process_language_table(lang))
        words.output_xml

        narrative = GherkinNarrativeWords.new(lang,'start-of-narrative')
        narrative.gherkinWordsExtract(process_language_table(lang))
        narrative.output_xml
    
        blockIdCollection.addLanguageBlockId(lang)
        keywordsCollection.addLanguageBlockId(lang)
        narrativeCollection.addLanguageBlockId(lang)
    end

    keywordsCollection.finish
    keywordsCollection.output_result

    blockIdCollection.finish
    blockIdCollection.output_result

    narrativeCollection.finish
    narrativeCollection.output_result

    puts endString

end


