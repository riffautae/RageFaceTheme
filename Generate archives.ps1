#########################################################################
## Rage Face Theme generation Script
##  Note: this relies on the pidgin files being up-to-date. 
#########################################################################

# Helper function from http://blogs.msdn.com/b/powershell/archive/2007/06/19/get-scriptdirectory.aspx

$Invocation = (Get-Variable MyInvocation -Scope 0).Value
$pwd = Split-Path $Invocation.MyCommand.Path
Set-Location $pwd

# Clear the generated folders first
Remove-Item RageFace.colloquyEmoticons\Contents\Resources\*
Remove-Item xml\*
Remove-Item php\*

# Ensure all files are lowercase first.

$files=get-childitem troll -recurse
foreach ($file in $files)
{
    # don't rename the readme; I like it to be all caps.
    if (($file.extension -cne "") -and ($file.name -cne $file.name.ToLower()))
    {
        Rename-Item $file.fullname $file.fullname.ToLower()
    }
}


$menuplist = [System.IO.StreamWriter] (Join-Path $pwd "RageFace.colloquyEmoticons\Contents\Resources\menu.plist")
$menuplist.WriteLine("(")

$emoticonsplist = [System.IO.StreamWriter] (Join-Path $pwd "RageFace.colloquyEmoticons\Contents\Resources\emoticons.plist")
$emoticonsplist.WriteLine("{")

$emoticonscss =  [System.IO.StreamWriter] (Join-Path $pwd "RageFace.colloquyEmoticons\Contents\Resources\emoticons.css")
$emoticonscss.WriteLine(".emoticon samp { display:none; }")
$emoticonscss.WriteLine(".emoticon:after { vertical-align: -25%; }")

$xmlOutput = [System.IO.StreamWriter] (Join-Path $pwd "xml\ragefaces.xml")
$xmlOutput.WriteLine("<?xml version='1.0' encoding='UTF-8'?>")
$xmlOutput.WriteLine("<rageFaces>")

$phpFaces = [System.IO.StreamWriter] (Join-Path $pwd "php\faces.php")
$phpFaces.WriteLine("<?php")
$phpFaces.WriteLine('function smiley($quote) {')
$phpFaces.WriteLine("")

$phpCodeArray = New-Object -TypeName "System.Text.StringBuilder"
[void]$phpCodeArray.AppendLine('$code = array();')

$phpImageArray = New-Object -TypeName "System.Text.StringBuilder"
[void]$phpImageArray.AppendLine('$img = array();')

$linecount = 0

Get-Content "troll\theme" | Foreach-Object {
    if ($linecount -gt 5)
    { 
        # menu.plist example:  {name = ":( - frown"; image="frown.gif"; insert=":(";},
        $menuplist.Write("  {name = `"")
        
        $Tokens = $_.Split(" ")
        # first is the filename, last is the token
        
        $token = $Tokens[$Tokens.Length - 1]
        $filename = $Tokens[0]
        
        $menuplist.Write($token)
        
        $menuplist.Write("`"; image = `"")
        $menuplist.Write($filename)
        
        $menuplist.Write("`"; insert = `"")
        $menuplist.Write($token)
        
        $menuplist.WriteLine("`";},")
        
        # emoticons.plist example:   frowngif = (":(");
        
        $emoticonsplist.Write("  ")
        
        $tokenWithoutColon = $token.Replace(":", "")
        
        $emoticonsplist.Write($tokenWithoutColon)
        $emoticonsplist.Write(" = (`"");
        $emoticonsplist.Write($token)
        $emoticonsplist.WriteLine("`");")
        
        # emoticons.css example: .emoticon.frowngif:after{ content: url("frown.gif"); }
        
        $emoticonscss.Write(".emoticon.")
        $emoticonscss.Write($tokenWithoutColon)
        $emoticonscss.Write(":after{ content: url(`"")
        $emoticonscss.Write($filename)
        $emoticonscss.WriteLine("`"); }")
        
        # build the XML file
        
        $xmlOutput.WriteLine("<face>")
        $xmlOutput.Write("<name>")
        $xmlOutput.Write($tokenWithoutColon)
        $xmlOutput.WriteLine("</name>")
        
        $xmlOutput.Write("<file>")
        $xmlOutput.Write($filename)
        $xmlOutput.WriteLine("</file>")
        $xmlOutput.WriteLine("</face>")
        
        # And the php file too
        
        # example line for code: $code[0] = "/:tdad/";
        [void]$phpCodeArray.Append('$code[')
        [void]$phpCodeArray.Append($linecount-6)
        [void]$phpCodeArray.Append("] = ""/")
        [void]$phpCodeArray.Append($token)
        [void]$phpCodeArray.AppendLine("/"";")
        
        # example line for image: $img[56] = "<img src=\"troll/smile2.png\" alt=\"!smile\" />";
        [void]$phpImageArray.Append('$img[')
        [void]$phpImageArray.Append($linecount-6)
        [void]$phpImageArray.Append('] = "<img src=\"troll/')
        [void]$phpImageArray.Append($filename)
        [void]$phpImageArray.Append('\" alt=\"!')
        [void]$phpImageArray.Append($tokenWithoutColon)
        [void]$phpImageArray.AppendLine('\" />";')
    }
    $linecount = $linecount+1
}

$menuplist.WriteLine(")")
$menuplist.close()

$emoticonsplist.WriteLine("}")
$emoticonsplist.Close()

$emoticonscss.WriteLine("")
$emoticonscss.Close()

$xmlOutput.WriteLine("</rageFaces>")
$xmlOutput.Close()

$phpFaces.WriteLine($phpCodeArray.ToString())
$phpFaces.WriteLine($phpImageArray.ToString())

$phpFaces.WriteLine("")
$phpFaces.WriteLine('  return preg_replace($code, $img, $quote);')
$phpFaces.WriteLine("")
$phpFaces.WriteLine("}")
$phpFaces.WriteLine("?>")

$phpFaces.Close()

# Copy the faces from the Pidgin dir to the colloquy dir

Copy-Item troll\*.png RageFace.colloquyEmoticons\Contents\Resources -force
Copy-Item troll\*.gif RageFace.colloquyEmoticons\Contents\Resources -force
Copy-Item troll\*.jpg RageFace.colloquyEmoticons\Contents\Resources -force

# ZIP ZE FILEZ

cmd /c generatezips.bat

