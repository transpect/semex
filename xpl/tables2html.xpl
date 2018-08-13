<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:isosts="http://www.iso.org/ns/isosts"
  xmlns:c="http://www.w3.org/ns/xproc-step" version="1.0"
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:tr="http://transpect.io"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:htmltable="http://transpect.io/htmltable"
  xmlns:SemEx="http://le-tex.de/ns/SemEx"
  type="isosts:tables2html" name="tables2html">
  
  <p:documentation></p:documentation>

  <p:input port="source" primary="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>Either a (N)ISO STS document or a “docs” document for a list of standards to convert.</p>
      <p>Examples for a docs document:</p>
      <pre>&lt;docs set="test" count="1">
  &lt;doc>
    &lt;path>1/4/14067.5/20110100.x1ca68b7/d1ca68b7.xml&lt;/path>
  &lt;/doc>
  &lt;doc>
    &lt;number>14067-5&lt;/number>
    &lt;date>2011-01&lt;/date>
  &lt;/doc>
&lt;/docs></pre>
      <p>Either path or a number/date tuple must be given for a doc. (In the previous example, each doc 
      will point to the same document, so it would be processed twice).</p>
    </p:documentation>
  </p:input>
  <p:input port="tr3k2nisosts-xsl">
    <p:document href="http://customers.le-tex.de/beuth/tr3k2isosts/xsl/tr3k2nisosts.xsl"/>
    <p:documentation>XSLT stylesheet for TR3K to (N)ISO STS conversion.</p:documentation>
  </p:input>
  <p:input port="nisosts2html-xsl">
    <p:document href="http://customers.le-tex.de/beuth/tr3k2isosts/html-renderer-adaptations/sts2html-frontend-niso_beuth.xsl"/>
    <p:documentation>XSLT stylesheet for (N)ISO STS to HTML conversion.</p:documentation>
  </p:input>
  <p:input port="add-semantics-xsl">
    <p:document href="../xsl/add-semantics.xsl"/>
    <p:documentation>XSLT stylesheet for adding semantic markup to (N)ISO STS tables.</p:documentation>
  </p:input>
  <p:input port="quantities2html-xsl">
    <p:document href="../xsl/quantities2html.xsl"/>
    <p:documentation>XSLT stylesheet for quantity structure to HTML conversion.</p:documentation>
  </p:input>
  <p:input port="quantity-lookup">
    <p:document href="../xsl/quantity-lookup.xml"/>
    <p:documentation>XML document containing quantity lookup criteria.</p:documentation>
  </p:input>
  <p:input port="table-head-lookup">
    <p:document href="../xsl/table-head.xml"/>
    <p:documentation>XML document containing the target table's “th” elements.</p:documentation>
  </p:input>
  
  <p:option name="sts-base-dir" select="''">
    <p:documentation>Must be given if source is a “docs” document.</p:documentation>
  </p:option>
  <p:option name="debug" select="'no'"/>
  <p:option name="debug-dir-uri" select="''"/>
  <p:option name="xlsx-template" select="'http://this.transpect.io/a9s/beuth/html2xlsx/template.xlsx'"/>
  <p:option name="single-xlsx-tables" select="'no'"/>
  
  <p:output port="result" primary="true" sequence="true"/>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/html2xlsx/xpl/html2xlsx.xpl"/>
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl"/>
  <p:import href="http://transpect.io/xproc-util/recursive-directory-list/xpl/recursive-directory-list.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  <p:import href="http://transpect.io/xproc-util/insert-srcpaths/xpl/insert-srcpaths.xpl"/>
  
  
  <p:declare-step name="process-single-file" type="isosts:process-single-file">
    <p:documentation>Processes single input files (TR3K or (N)ISO STS).</p:documentation>
    <p:input port="source" primary="true"/>
    <p:input port="tr3k2sts-stylesheet"/>
    <p:input port="nisosts2html-stylesheet"/>
    <p:input port="add-semantics-stylesheet"/>
    <p:input port="quantities2html-stylesheet"/>
    <p:input port="quantity-lookup-file"/>
    <p:input port="table-head-lookup-file"/>
    <p:option name="debug" select="'no'"/>
    <p:option name="debug-dir-uri" select="''"/>
    <p:option name="xlsx-template" select="''"/>
    <p:option name="single-xlsx-tables" select="'no'"/>
    
    <p:output port="result" primary="true" sequence="true"><p:empty/></p:output>
    
    <p:variable name="base-dir" select="replace(p:base-uri(), '/[^/]+$', '')"/>
    <p:variable name="basename" select="replace(p:base-uri(), '^.*/([^/]+)\.xml$', '$1')"/>
    <p:variable name="debug-dir" select="if ($debug-dir-uri ne '') then $debug-dir-uri else concat($base-dir, '/debug')"/>
    
    <p:choose name="nisosts">
      <p:documentation>TR3K input documents will be converted to (N)ISO STS.</p:documentation>
      <p:when test="/*/local-name() eq 'tr'">
        <p:output port="result" primary="true"/>
        <p:xslt name="tr3k2nisosts-conversion">
          <p:input port="parameters"><p:empty/></p:input>
          <p:input port="stylesheet">
            <p:pipe port="tr3k2sts-stylesheet" step="process-single-file"/>
          </p:input>
          <p:with-param name="nat" select="'yes'"/>
          <p:with-param name="output-auxiliary-files" select="'no'"/>
          <p:with-param name="debug" select="'no'"/>
          <p:with-param name="terminate-on-error" select="'yes'"/>
        </p:xslt>
      </p:when>
      <p:otherwise>
        <p:output port="result" primary="true"/>
        <p:identity name="no-tr3k2nisosts-conversion-needed"/>
      </p:otherwise>
    </p:choose>
    
    <tr:store-debug>
      <p:with-option name="pipeline-step" select="concat('01_', $basename, '_nisosts')"/>
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir"/>
    </tr:store-debug>
    
    <tr:insert-srcpaths name="insert-srcpaths"/>
    
    <p:viewport match="*[*:tr]" name="normalize-tables">
      <p:xslt name="normalize">
        <p:input port="parameters"><p:empty/></p:input>
        <p:input port="stylesheet">
          <p:inline>
            <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
              <xsl:import href="http://this.transpect.io/htmltables/xsl/html-tables-normalize.xsl"/>
              <xsl:template match="/*">
                <xsl:variable name="prelim" as="element(*)">
                  <xsl:sequence select="htmltable:normalize(.)" />  
                </xsl:variable>
                <xsl:apply-templates select="$prelim"/>
              </xsl:template>
              <xsl:template match="@* | node()">
                <xsl:copy>
                  <xsl:apply-templates select="@*, node()"/>
                </xsl:copy>
              </xsl:template>
              <xsl:template match="@rowspan | @colspan">
                <xsl:attribute name="data-{name()}" select="."/>
              </xsl:template>
            </xsl:stylesheet>
          </p:inline>
        </p:input>
      </p:xslt>      
    </p:viewport>
    
    <tr:store-debug>
      <p:with-option name="pipeline-step" select="concat('03_', $basename, '_normalize-tables')"/>
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir"/>
    </tr:store-debug>
    
    <p:viewport match="*:table-wrap[@*:id]" name="add-semantics_add-quantities">
      <p:xslt initial-mode="add-quantities">
        <p:input port="parameters"><p:empty/></p:input>
        <p:input port="stylesheet">
          <p:pipe port="add-semantics-stylesheet" step="process-single-file"/>          
        </p:input>
        <p:input port="source">
          <p:pipe port="current" step="add-semantics_add-quantities"/>
          <p:pipe port="quantity-lookup-file" step="process-single-file"/>
        </p:input>
      </p:xslt>     
    </p:viewport>
    
    <tr:store-debug>
      <p:with-option name="pipeline-step" select="concat('05_', $basename, '_identify-quantities')"/>
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir"/>
    </tr:store-debug>
    
    <p:viewport match="*:table-wrap[@*:id]" name="add-semantics_enhance-quantities">
      <p:xslt initial-mode="enhance-quantities">
        <p:input port="parameters"><p:empty/></p:input>
        <p:input port="stylesheet">
          <p:pipe port="add-semantics-stylesheet" step="process-single-file"/>
        </p:input>
      </p:xslt>
      <p:xslt name="insert-std-infos">
        <p:input port="stylesheet">
          <p:inline>
            <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" 
              xmlns:isosts="http://www.iso.org/ns/isosts" xmlns:c="http://www.w3.org/ns/xproc-step"
              xmlns:cx="http://xmlcalabash.com/ns/extensions" xmlns:tr="http://transpect.io"
              xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:htmltable="http://transpect.io/htmltable"
              xmlns:SemEx="http://le-tex.de/ns/SemEx" exclude-result-prefixes="#all">
              <xsl:param name="doc-id"/>
              <xsl:param name="std-number"/>
              <xsl:param name="std-date"/>
              <xsl:param name="title_de"/>
              <xsl:param name="title_en"/>
              <xsl:template match="*:quantity[@*:type eq 'primary']">
                <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <doc-id xmlns="http://le-tex.de/ns/SemEx"><xsl:value-of select="$doc-id"/></doc-id>
                  <std-number xmlns="http://le-tex.de/ns/SemEx"><xsl:value-of select="$std-number"/></std-number>
                  <std-date xmlns="http://le-tex.de/ns/SemEx"><xsl:value-of select="$std-date"/></std-date>
                  <title_de xmlns="http://le-tex.de/ns/SemEx"><xsl:value-of select="$title_de"/></title_de>
                  <title_en xmlns="http://le-tex.de/ns/SemEx"><xsl:value-of select="$title_en"/></title_en>
                  <xsl:copy-of select="node()"/>
                </xsl:copy>              
              </xsl:template>
              <xsl:template match="@* | node()">
                <xsl:copy copy-namespaces="no">
                  <xsl:apply-templates select="@*, node()"/>
                </xsl:copy>
              </xsl:template>
            </xsl:stylesheet>
          </p:inline>
        </p:input>
        <p:input port="parameters"><p:empty/></p:input>
        <p:with-param name="doc-id" select="/*/descendant::*:std-id[1]"><p:pipe port="result" step="nisosts"/></p:with-param>
        <p:with-param name="std-number" select="/*/descendant::*:doc-ref[1]"><p:pipe port="result" step="nisosts"/></p:with-param>
        <p:with-param name="std-date" select="/*/descendant::*:release-date[1]"><p:pipe port="result" step="nisosts"/></p:with-param>
        <p:with-param name="title_de" select="/*/descendant::*:title-wrap[@xml:lang='de'][1]/*:main"><p:pipe port="result" step="nisosts"/></p:with-param>
        <p:with-param name="title_en" select="/*/descendant::*:title-wrap[@xml:lang='en'][1]/*:main"><p:pipe port="result" step="nisosts"/></p:with-param>
      </p:xslt>
    </p:viewport>
    
    <tr:store-debug>
      <p:with-option name="pipeline-step" select="concat('07_', $basename, '_enhance-quantities')"/>
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir"/>
    </tr:store-debug>
    
    <p:delete match="SemEx:* | @SemEx:*" name="delete-SemEx-contents"/>
    <p:delete match="@*:srcpath" name="delete-srcpaths"/>
    
    <p:xslt name="nisosts2html">
      <p:documentation>NISOSTS to HTML conversion.</p:documentation>
      <p:input port="parameters"><p:empty/></p:input>
      <p:input port="stylesheet">
        <p:pipe port="nisosts2html-stylesheet" step="process-single-file"/>
      </p:input>
    </p:xslt>
    
    <tr:store-debug>
      <p:with-option name="pipeline-step" select="concat('10_', $basename, '_nisosts2html')"/>
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir"/>
    </tr:store-debug>
    
    <p:sink/>
    
    <tr:file-uri name="xlsx-template-file-uri">
      <p:with-option name="filename" select="$xlsx-template"/>
      <p:input port="catalog">
        <p:document href="http://this.transpect.io/xmlcatalog/catalog.xml"/>
      </p:input>
      <p:input port="resolver">
        <p:document href="http://transpect.io/xslt-util/xslt-based-catalog-resolver/xsl/resolve-uri-by-catalog.xsl"/>
      </p:input>
    </tr:file-uri>
    
    <p:identity name="identity-html">
      <p:input port="source"><p:pipe port="result" step="nisosts2html"/></p:input>
    </p:identity>
    
    <p:viewport match="*:div[@*:class eq 'sts-table-wrap'][@*:id]" name="extract-tables">
      <p:output port="result" primary="true"><p:empty/></p:output>
      
      <p:variable name="table-id" select="/*/@*:id"/>
      
      <p:sink name="sink5"/>
      
      <p:insert match="*:body" name="insert-body" position="first-child">
        <p:input port="source">
          <p:inline>
            <html xmlns="http://www.w3.org/1999/xhtml">
              <head>
                <meta charset="UTF-8"/>
                <style>
                  th { border: 2px solid black }
                  td { border: 1px solid black }
                  [data-rowspan-part] { color: #567}
                  [data-colspan-part] { background-color: #ede }
                </style>
              </head>
              <body></body>
            </html>
          </p:inline>
        </p:input>
        <p:input port="insertion">
          <p:pipe port="current" step="extract-tables"/>
        </p:input>
      </p:insert>
      
      <p:store name="store-htmltable" media-type="xhtml" omit-xml-declaration="false">
        <p:with-option name="href" select="concat($base-dir, '/tables/html/', $basename, '_', $table-id, '.xhtml')"/>        
      </p:store>
      
      <p:choose>
        <p:when test="$single-xlsx-tables = ('yes', 'true', 'on')">
          <tr:html2xlsx name="convert-html2xlsx">
            <p:input port="source">
              <p:pipe port="current" step="extract-tables"/>
            </p:input>
            <p:with-option name="template" select="/c:result/@local-href">
              <p:pipe port="result" step="xlsx-template-file-uri"/>
            </p:with-option>
            <p:with-option name="out-dir-uri" select="concat($base-dir, '/tables/xlsx/', $basename, '_', $table-id, '.xlsx')"/>
            <p:with-option name="debug" select="$debug"/>
            <p:with-option name="debug-dir-uri" select="concat($debug-dir, '/', $basename, '_', $table-id)"/>
          </tr:html2xlsx>
          <p:sink/>
        </p:when>
        <p:otherwise>
          <p:sink>
            <p:input port="source"><p:empty/></p:input>
          </p:sink>
        </p:otherwise>
      </p:choose>
      
    </p:viewport>
    
    <p:sink name="sink_1"/>
    
    
    <p:filter select="//SemEx:quantity[@*:type eq 'primary']
                                      [not(*:value[@*:status eq 'n.a.'])]
                                      [descendant::*:with-material-id[normalize-space()]]" 
      name="filter-primary-quantities" cx:depends-on="add-semantics_enhance-quantities">
      <p:input port="source">
        <p:pipe port="result" step="add-semantics_enhance-quantities"/>
      </p:input>
    </p:filter>
    <p:wrap-sequence wrapper="data" wrapper-namespace="http://le-tex.de/ns/SemEx" name="wrap-quantities"/>
    <p:xslt name="delete-namespaces">
      <p:input port="parameters"><p:empty/></p:input>
      <p:input port="stylesheet">
        <p:inline>
          <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
            <xsl:template match="@* | node()">
              <xsl:copy copy-namespaces="no">
                <xsl:apply-templates select="@*, node()"/>
              </xsl:copy>
            </xsl:template>
          </xsl:stylesheet>
        </p:inline>
      </p:input>
    </p:xslt>
    
    <p:store name="store-quantities" media-type="xml" omit-xml-declaration="false" indent="true">
      <p:with-option name="href" select="concat($base-dir, '/tables/', $basename, '_quantities.xml')"/>        
    </p:store>
    
    <p:xslt name="quantities2html" template-name="main" cx:depends-on="wrap-quantities">
      <p:input port="source">
        <p:pipe port="result" step="wrap-quantities"/>
        <p:pipe port="table-head-lookup-file" step="process-single-file"/>
      </p:input>
      <p:input port="parameters"><p:empty/></p:input>
      <p:input port="stylesheet"><p:pipe port="quantities2html-stylesheet" step="process-single-file"/></p:input>
    </p:xslt>
    
    <p:store name="store-quantities-xhtml" media-type="xhtml" omit-xml-declaration="false" indent="true">
      <p:with-option name="href" select="concat($base-dir, '/tables/', $basename, '_quantities.xhtml')"/>        
    </p:store>
    
    <tr:html2xlsx name="convert-html2xlsx_quantities" cx:depends-on="extract-tables">
      <p:input port="source">
        <p:pipe port="result" step="quantities2html"/>
      </p:input>
      <p:with-option name="template" select="/c:result/@local-href">
        <p:pipe port="result" step="xlsx-template-file-uri"/>
      </p:with-option>
      <p:with-option name="out-dir-uri" select="concat($base-dir, '/tables/', $basename, '_quantities.xlsx')"/>
      <p:with-option name="debug" select="$debug"/>
      <p:with-option name="debug-dir-uri" select="concat($debug-dir, '/', $basename, '_quantities')"/>
      <p:with-option name="th-template-row" select="1"/>
      <p:with-option name="td-template-row" select="2"/>
    </tr:html2xlsx>
    
    <p:sink/>
    
  </p:declare-step>
  
  
  
  <p:choose>
    <p:documentation>Handles different kinds of input documents: “docs” document, TR3K, (N)ISO STS.</p:documentation>
    
    <p:when test="/*/local-name() eq 'docs'">
      <p:documentation>Input file is a “docs” document.</p:documentation>
      <p:for-each>
        <p:iteration-source select="//*:doc[*:number and *:date]"/>
        <p:variable name="number" select="for $n in /*/*:number 
          return concat(  substring($n, 1, 1), '/',
                          if (starts-with($n, '1')) then concat(substring($n, 2, 1),'/') 
                          else '',
                          translate($n, '-', '.')
                        )"/>
        <p:variable name="date" select="/*/*:date"/>
        <tr:file-uri name="path-uri" make-unique="false">
          <p:with-option name="filename" select="$sts-base-dir"/>
        </tr:file-uri>        
        <tr:recursive-directory-list name="directory-list">
          <p:with-option name="path" select="concat(replace(/*/@local-href, '([^/])$', '$1/'), $number)"/>
        </tr:recursive-directory-list>
        <p:group>
          <p:variable name="path" select="//c:directory[starts-with(@*:name, replace($date, '-', ''))]/@xml:base"/>
          <p:for-each>
            <p:iteration-source select="//c:directory[@xml:base eq $path]/c:file[ends-with(@*:name, '.xml')]"/>
            <p:load>
              <p:with-option name="href" select="concat($path,'/',/*/@*:name)"/>
            </p:load>
            <isosts:process-single-file>
              <p:input port="tr3k2sts-stylesheet"><p:pipe port="tr3k2nisosts-xsl" step="tables2html"/></p:input>
              <p:input port="nisosts2html-stylesheet"><p:pipe port="nisosts2html-xsl" step="tables2html"/></p:input>
              <p:input port="add-semantics-stylesheet"><p:pipe port="add-semantics-xsl" step="tables2html"/></p:input>
              <p:input port="quantities2html-stylesheet"><p:pipe port="quantities2html-xsl" step="tables2html"/></p:input>
              <p:input port="quantity-lookup-file"><p:pipe port="quantity-lookup" step="tables2html"/></p:input>
              <p:input port="table-head-lookup-file"><p:pipe port="table-head-lookup" step="tables2html"/></p:input>
              <p:with-option name="debug" select="$debug"/>
              <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
              <p:with-option name="xlsx-template" select="$xlsx-template"/>
              <p:with-option name="single-xlsx-tables" select="$single-xlsx-tables"/>
            </isosts:process-single-file>
          </p:for-each>
        </p:group>
      </p:for-each>
    </p:when>
    
    <p:otherwise>
      <p:documentation>Input file is a TR3K or (N)ISO STS document.</p:documentation>
      <isosts:process-single-file>
        <p:input port="tr3k2sts-stylesheet"><p:pipe port="tr3k2nisosts-xsl" step="tables2html"/></p:input>
        <p:input port="nisosts2html-stylesheet"><p:pipe port="nisosts2html-xsl" step="tables2html"/></p:input>
        <p:input port="add-semantics-stylesheet"><p:pipe port="add-semantics-xsl" step="tables2html"/></p:input>
        <p:input port="quantities2html-stylesheet"><p:pipe port="quantities2html-xsl" step="tables2html"/></p:input>
        <p:input port="quantity-lookup-file"><p:pipe port="quantity-lookup" step="tables2html"/></p:input>
        <p:input port="table-head-lookup-file"><p:pipe port="table-head-lookup" step="tables2html"/></p:input>
        <p:with-option name="debug" select="$debug"/>
        <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
        <p:with-option name="xlsx-template" select="$xlsx-template"/>
        <p:with-option name="single-xlsx-tables" select="$single-xlsx-tables"/>
      </isosts:process-single-file>      
    </p:otherwise>

  </p:choose>

  
</p:declare-step>