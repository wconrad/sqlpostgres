module RDoc
module Page


FONTS = "Verdana, Arial, Helvetica, sans-serif"

STYLE = %{
body,td,p { font-family: %fonts%; 
       color: #000040;
}

.attr-rw { font-size: xx-small; color: #444488 }

.title-row { background-color: #CCCCFF;
             color:      #000010;
}

.big-title-font { 
  color: black;
  font-weight: bold;
  font-family: %fonts%; 
  font-size: large; 
  height: 60px;
  padding: 10px 3px 10px 3px;
}

.small-title-font { color: black;
                    font-family: %fonts%;
                    font-size:10; }

.aqua { color: black }

.method-name, .attr-name {
      font-family: font-family: %fonts%; 
      font-weight: bold;
      font-size: small;
      margin-left: 20px;
      color: #000033;
}

.tablesubtitle, .tablesubsubtitle {
   width: 100%;
   margin-top: 1ex;
   margin-bottom: .5ex;
   padding: 5px 0px 5px 3px;
   font-size: large;
   color: black;
   background-color: #CCCCFF;
   border: thin;
}

.name-list {
  margin-left: 5px;
  margin-bottom: 2ex;
  line-height: 105%;
}

.description {
  margin-left: 5px;
  margin-bottom: 2ex;
  line-height: 105%;
  font-size: small;
}

.methodtitle {
  font-size: small;
  font-weight: bold;
  text-decoration: none;
  color: #000033;
  background-color: white; 
}

.srclink {
  font-size: small;
  font-weight: bold;
  text-decoration: none;
  color: #0000DD;
  background-color: white;
}

.paramsig {
   font-size: small;
}

.srcbut { float: right }

}


############################################################################


BODY = %{
<html><head>
  <title>%title%</title>
  <meta http-equiv="Content-Type" content="text/html; charset=%charset%">
  <link rel=StyleSheet href="%style_url%" type="text/css" media=screen>
  <script type="text/javascript" language="JavaScript">
  <!--
  function popCode(url) {
    parent.frames.source.location = url
  }
  //-->
  </script>
</head>
<body bgcolor="white">

!INCLUDE!  <!-- banner header -->

IF:diagram
<table width="100%"><tr><td align="center">
%diagram%
</td></tr></table>
ENDIF:diagram

IF:description
<div class="description">%description%</div>
ENDIF:description

IF:requires
<table cellpadding=5 width="100%">
<tr><td class="tablesubtitle">Required files</td></tr>
</table><br>
<div class="name-list">
START:requires
HREF:aref:name:
END:requires
ENDIF:requires
</div>

IF:methods
<table cellpadding=5 width="100%">
<tr><td class="tablesubtitle">Methods</td></tr>
</table><br>
<div class="name-list">
START:methods
HREF:aref:name:,
END:methods
</div>
ENDIF:methods

IF:attributes
<table cellpadding=5 width="100%">
<tr><td class="tablesubtitle">Attributes</td></tr>
</table><br>
<table cellspacing=5>
START:attributes
     <tr valign="top">
       <td align="center" class="attr-rw">&nbsp;[%rw%]&nbsp;</td>
       <td class="attr-name">%name%</td>
       <td>%a_desc%</td>
     </tr>
END:attributes
</table>
ENDIF:attributes

IF:classlist
<table cellpadding=5 width="100%">
<tr><td class="tablesubtitle">Classes and Modules</td></tr>
</table><br>
%classlist%<br>
ENDIF:classlist

  !INCLUDE!  <!-- method descriptions -->

</body>
</html>
}

###############################################################################

FILE_PAGE = <<_FILE_PAGE_
<table width="100%">
 <tr class="title-row">
 <td><table width="100%"><tr>
   <td class="big-title-font" colspan=2><font size=-3><B>File</B><BR></font>%short_name%</td>
   <td align="right"><table cellspacing=0 cellpadding=2>
         <tr>
           <td  class="small-title-font">Path:</td>
           <td class="small-title-font">%full_path%</td>
         </tr>
         <tr>
           <td class="small-title-font">Modified:</td>
           <td class="small-title-font">%dtm_modified%</td>
         </tr>
        </table>
    </td></tr></table></td>
  </tr>
</table><br>
_FILE_PAGE_

###################################################################

CLASS_PAGE = %{
<table width="100%" border=0 cellspacing=0>
 <tr class="title-row">
 <td class="big-title-font">
   <font size=-3><B>%classmod%</B><BR></font>%full_name%
 </td>
 <td align="right">
   <table cellspacing=0 cellpadding=2>
     <tr valign="top">
      <td class="small-title-font">In:</td>
      <td class="small-title-font">
START:infiles
HREF:full_path_url:full_path:
END:infiles
      </td>
     </tr>
IF:parent
     <tr>
      <td class="small-title-font">Parent:</td>
      <td class="small-title-font">
IF:par_url
        <a href="%par_url%" class="cyan">
ENDIF:par_url
%parent%
IF:par_url
         </a>
ENDIF:par_url
      </td>
     </tr>
ENDIF:parent
   </table>
  </td>
  </tr>
</table><br>
}

###################################################################

METHOD_LIST = %{
IF:includes
<div class="tablesubsubtitle">Included modules</div><br>
<div class="name-list">
START:includes
    <span class="method-name">HREF:aref:name:</span>
END:includes
</div>
ENDIF:includes

IF:method_list
START:method_list
IF:methods
<table cellpadding=5 width="100%">
<tr><td class="tablesubtitle">%type% %category% methods</td></tr>
</table>
START:methods
<table width="100%" cellspacing = 0 cellpadding=5 border=0>
<tr><td class="methodtitle">
<a name="%aref%">
<b>%name%</b>%params% 
IF:codeurl
<a href="%codeurl%" target="source" class="srclink">src</a>
ENDIF:codeurl
</a></td></tr>
</table>
IF:m_desc
<div class="description">
%m_desc%
</div>
ENDIF:m_desc
END:methods
ENDIF:methods
END:method_list
ENDIF:method_list
}

=begin
=end

########################## Source code ##########################

SRC_PAGE = %{
<html>
<head><title>%title%</title>
<meta http-equiv="Content-Type" content="text/html; charset=%charset%">
<style>
  .kw { color: #3333FF; font-weight: bold }
  .cmt { color: green; font-style: italic }
  .str { color: #662222; font-style: italic }
  .re  { color: #662222; }
</style>
</head>
<body bgcolor="white">
<pre>%code%</pre>
</body>
</html>
}

########################## Index ################################

FR_INDEX_BODY = %{
!INCLUDE!
}

FILE_INDEX = %{
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=%charset%">
<style>
<!--
  body {
background-color: #ddddff;
     font-family: #{FONTS}; 
       font-size: 11px; 
      font-style: normal;
     line-height: 14px; 
           color: #000040;
  }
div.banner {
  background: #0000aa;
  color:      white;
  padding: 1;
  margin: 0;
  font-size: 90%;
  font-weight: bold;
  line-height: 1.1;
  text-align: center;
  width: 100%;
}
  
-->
</style>
<base target="docwin">
</head>
<body>
<div class="banner">%list_title%</div>
START:entries
<a href="%href%">%name%</a><br>
END:entries
</body></html>
}

CLASS_INDEX = FILE_INDEX
METHOD_INDEX = FILE_INDEX

INDEX = %{
<html>
<head>
  <title>%title%</title>
  <meta http-equiv="Content-Type" content="text/html; charset=%charset%">
</head>

<frameset cols="20%,*">
    <frameset rows="15%,35%,50%">
        <frame src="fr_file_index.html"   title="Files" name="Files">
        <frame src="fr_class_index.html"  name="Classes">
        <frame src="fr_method_index.html" name="Methods">
    </frameset>
    <frameset rows="80%,20%">
      <frame  src="%initial_page%" name="docwin">
      <frame  src="blank.html" name="source">
    </frameset>
    <noframes>
          <body bgcolor="white">
            Click <a href="html/index.html">here</a> for a non-frames
            version of this page.
          </body>
    </noframes>
</frameset>

</html>
}

# and a blank page to use as a target
BLANK = %{
<html><body bgcolor="white"></body></html>
}

def write_extra_pages
  template = TemplatePage.new(BLANK)
  File.open("blank.html", "w") { |f| template.write_html_on(f, {}) }
end

end
end
