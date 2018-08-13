<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:SemEx="http://le-tex.de/ns/SemEx" 
  exclude-result-prefixes="xs"
  version="2.0">
  
  <xsl:variable name="quantity-lookup-criteria" select="collection()[2]"/>  
  <xsl:variable name="header-keywords" as="xs:string+" select="'Kurzname', 'Stahlkurzname', 'Werkstoffnummer'"/> 
  <xsl:variable name="pseudo-header-keywords" as="xs:string+" select="'Nennwanddicke', 'emperatur'"/>
  <xsl:variable name="exclude-elements" as="xs:string+" select="'xref'"/>
  <xsl:variable name="exclude-quantities" as="xs:string+" select="'bezeichnung', 'waermebehandlung_abkuehlung', 'werkstoffnummer'"/>  
  <xsl:variable name="quantity-lookup-elements" as="xs:string+" select="'td', 'th', 'caption'"/>
  <xsl:variable name="not-available-strings" as="xs:string+" select="'-', '', '–'"/>
  
  
  <xsl:template match="@* | node()" priority="-1" mode="#all">
    <xsl:copy copy-namespaces="yes">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*:td | *:th[SemEx:is-pseudo-head(.)] | *:table-wrap | *:caption" mode="add-quantities">
    <xsl:copy copy-namespaces="yes">
      <xsl:attribute name="SemEx:thead" select="SemEx:belongs-to-head(.)"/>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:sequence select="SemEx:quantity-lookup(., $quantity-lookup-criteria)"/>
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="SemEx:quantity[@*:type eq 'primary']" mode="enhance-quantities">
    <xsl:copy copy-namespaces="yes">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="node()" mode="#current"/>
      <xsl:sequence select="SemEx:enhance-quantities(.)"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="SemEx:quantity[@*:type eq 'primary'][@*:name=$exclude-quantities]" 
    mode="enhance-quantities" priority="1.5"/>
  
  
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  
  
  <xsl:function name="SemEx:belongs-to-head" as="xs:boolean">
    <xsl:param name="context" as="node()"/>
    <xsl:value-of 
      select="if ($context[self::*:th or self::*:caption]) then true() else
      if ($context/ancestor-or-self::*:tr[1]/*[1 or 2][some $keyword in $header-keywords satisfies contains(., $keyword)]) 
      then true() else false()"/>
  </xsl:function>
  
  <xsl:function name="SemEx:is-pseudo-head" as="xs:boolean">
    <xsl:param name="context" as="node()"/>
    <xsl:value-of select="
      if ($context/ancestor-or-self::*:tr[1]/*[1 or 2][some $keyword in $header-keywords satisfies contains(., $keyword)]) then true() else
      if ($context/ancestor::*:thead and (some $p in $pseudo-header-keywords satisfies contains(replace($context, '&#x2d;', ''), $p))) then true()
      else false()"/>
  </xsl:function>
  
  <xsl:function name="SemEx:find-min-and-max" as="element()*">
    <xsl:param name="value" as="xs:string"/>
    <xsl:analyze-string select="$value" regex="^([&#x3e;&#x2265;]\s?)?([0-9,.]+)(\s(bis|[&#x2264;&#x3c;&lt;]|T))+\s?([0-9,.]+)\s?$">
      <xsl:matching-substring>
        <min><xsl:value-of select="regex-group(2)"/></min>
        <max><xsl:value-of select="regex-group(5)"/></max>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:analyze-string select="." regex="([&#x3e;]\s?)([0-9,.]+)">
          <xsl:matching-substring>
            <min><xsl:value-of select="regex-group(2)"/></min>
          </xsl:matching-substring>
          <xsl:non-matching-substring>
            <xsl:analyze-string select="." regex="[^0-9]*(bis|[&#x2264;&#x3c;&lt;])\s?([0-9,.]+)\s?(mm)?\s?$">
              <xsl:matching-substring>
                <max><xsl:value-of select="regex-group(2)"/></max>
              </xsl:matching-substring>
              <xsl:non-matching-substring/>
            </xsl:analyze-string>
          </xsl:non-matching-substring>
        </xsl:analyze-string>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:function>
  
  
  <xsl:function name="SemEx:quantity-lookup" as="element(SemEx:quantity-lookup)*">
    <xsl:param name="context" as="element(*)"/><!-- caption, td, th or table-wrap -->
    <xsl:param name="criteria" as="document-node(element(SemEx:quantity-lookup-criteria))"/>
    
    <xsl:variable name="col-heading" as="node()*"
      select="$context/ancestor::*:table[1]//*:th[. &lt;&lt; $context][not(SemEx:is-pseudo-head(.))]
                                                 [xs:integer(@data-colnum) eq xs:integer($context/@data-colnum)]
                                                 (:[xs:integer(@data-rownum) lt xs:integer($context/@data-rownum)]:)"/>
    <xsl:variable name="pseudo-col-heading" as="node()*"
      select="$context/ancestor::*:table[1]//*[. &lt;&lt; $context][SemEx:is-pseudo-head(.)]
                                              [xs:integer(@data-colnum) eq xs:integer($context/@data-colnum)],
              if (SemEx:is-pseudo-head($context)) then $context else ()"/>
    <xsl:variable name="expanded-col-heading" as="node()*" 
      select="$col-heading, $pseudo-col-heading"/>
    <xsl:variable name="relevant-col-heading" as="node()*" 
      select="if (SemEx:is-pseudo-head($context)) then $pseudo-col-heading else $expanded-col-heading"/>
    
    <xsl:variable name="matching-quantities" as="element()*"
      select="$quantity-lookup-criteria//*:quantity
      [(((every $or in descendant::*:condition[@type eq 'identify']//*:heading-sequence/*:or satisfies
          (some $o in $or/*:heading 
           satisfies (some $s in $relevant-col-heading[not(local-name()=$exclude-elements)] satisfies matches($s, $o))))
        or (not(exists(descendant::*:condition[@type eq 'identify']//*:heading-sequence/*:or))))
        and
       (every $h in descendant::*:condition[@type eq 'identify']//*:heading-sequence/*:heading 
          satisfies (some $s in $relevant-col-heading[not(local-name()=$exclude-elements)] satisfies matches($s, $h)))
       )
       or not(exists(descendant::*:condition[@type eq 'identify']//*:heading))
       or (     $context/self::*:caption 
            and exists(descendant::*:condition[@type eq 'identify']/*:or/*:table-title) 
            and matches($context, descendant::*:condition[@type eq 'identify']/*:or/*:table-title)
          )
      ]
      [   not(exists(descendant::*:condition[@type eq 'identify']//*:value)) 
       or (some $v in descendant::*:condition[@type eq 'identify']//*:value satisfies matches(string-join($context/node()[not(local-name()=$exclude-elements)], ''), $v))]"/>    
    
    <xsl:variable name="relevant-quantities" as="element()*"
      select="$matching-quantities[@*:type eq (if ($context[SemEx:belongs-to-head(.)]) then 'secondary' else 'primary')]"/>
    
    <xsl:if test="$relevant-quantities">
      <quantity-lookup xmlns="http://le-tex.de/ns/SemEx">
        <xsl:for-each select="$relevant-quantities">
          <xsl:variable name="value-str" as="xs:string?">
            <xsl:for-each select="string-join($context/descendant::text()[not(ancestor::*/local-name()=$exclude-elements)], '')">
              <xsl:choose>
                <xsl:when test="$relevant-quantities//*:use[@*:replace]">
                  <xsl:value-of select="replace(., $relevant-quantities//*:use/@*:replace, $relevant-quantities//*:use/@*:by)"/>
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="normalize-space(.)"/></xsl:otherwise>
              </xsl:choose>             
            </xsl:for-each>
          </xsl:variable> 
          <quantity>
            <xsl:sequence select="@*:name, @*:type, @*:secondary-quantities"/>
            <value>
              <xsl:for-each select="$value-str">
                <xsl:if test="current()=$not-available-strings"><xsl:attribute name="status" select="'n.a.'"/></xsl:if>
                <xsl:value-of select="current()"/>
              </xsl:for-each>
            </value>
            <xsl:for-each select="SemEx:find-min-and-max($value-str)/self::*:min[normalize-space()]">
              <min-value include="{if (matches($value-str, '^[&#x3e;]')) then 'no' else 'yes'}"><xsl:value-of select="."/></min-value>
            </xsl:for-each>
            <xsl:for-each select="SemEx:find-min-and-max($value-str)/self::*:max[normalize-space()]">
              <max-value include="{if (matches($value-str, '^[&#x3c;]')) then 'no' else 'yes'}"><xsl:value-of select="."/></max-value>
            </xsl:for-each>
            <unit>
              <xsl:value-of select="for $u in current()//*:unit return
                (if ($u/@*:regex eq 'yes') 
                  then $u[some $e in $relevant-col-heading satisfies matches($e, .)] 
                  else $relevant-col-heading[$u eq .][not(local-name()=$exclude-elements)])"/>
            </unit>
            <address>
              <srcpath><xsl:value-of select="$context/@srcpath"/></srcpath>
              <tab-id><xsl:value-of select="$context/ancestor::*:table-wrap[1]/@*:id"/></tab-id>
              <tab-body-col><xsl:value-of select="$context/@data-colnum"/></tab-body-col>
              <tab-body-row><xsl:value-of select="$context/@data-rownum"/></tab-body-row>
            </address>
            <notes>
              <xsl:for-each select="(for $rid in distinct-values($relevant-col-heading//*:xref/@rid) 
                                     return $relevant-col-heading/ancestor::*:table-wrap[1]//*:fn[@id eq $rid],
                                     for $r in distinct-values($context//*:xref/@rid) 
                                     return $context/ancestor::*:table-wrap[1]//*:fn[@id eq $r]
                                    )">
                <note><xsl:value-of select="node() except *:label"/></note>
              </xsl:for-each>
            </notes>
          </quantity>
        </xsl:for-each>
      </quantity-lookup>
    </xsl:if>
   
  </xsl:function>
  
  
  
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  
  
  <xsl:function name="SemEx:enhance-quantities" as="element()*">
    <xsl:param name="context" as="element(SemEx:quantity)"/>
    <xsl:variable name="elt" as="element()" select="$context/ancestor::*[local-name()=$quantity-lookup-elements][1]"/>
    <xsl:variable name="secondary-quantities" as="element(SemEx:quantity)*">
      <xsl:for-each select="tokenize($context/@*:secondary-quantities, '\s')">
        <xsl:variable name="most-specific" as="element(SemEx:quantity)*">
          <xsl:sequence 
            select="$context/ancestor::*:table[1]//*:quantity[@*:name eq current()]
                                                             [ancestor::*[local-name()=$quantity-lookup-elements][1]
                                                                         [       (xs:integer(@data-colnum) eq xs:integer($elt/@data-colnum)
                                                                              and not(xs:integer(@data-rowspan-part) gt 1))
                                                                          or (xs:integer(@data-rownum) eq xs:integer($elt/@data-rownum)
                                                                              and not(xs:integer(@data-colspan-part) gt 1)
                                                                              and (ancestor::*[local-name()=('thead','tbody')][1] 
                                                                                  is $elt/ancestor::*[local-name()=('thead','tbody')][1]))
                                                                          ]
                                                              ]"/>          
        </xsl:variable>
        <xsl:variable name="less-specific" as="element(SemEx:quantity)*">
          <xsl:sequence select="$context/ancestor::*:table-wrap[1]//*:caption//*:quantity[@*:name eq current()]"></xsl:sequence>
        </xsl:variable>
        <xsl:sequence select="if (exists($most-specific)) then $most-specific else $less-specific"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:for-each-group select="$secondary-quantities" group-by="string-join((@*:name,*:unit),'')">
      <with-quantity xmlns="http://le-tex.de/ns/SemEx" name="{current-group()[1]/@*:name}">
        <xsl:sequence select="current-group()/*:min-value"/>
        <xsl:sequence select="current-group()/*:max-value"/>
        <value><xsl:value-of select="string-join(current-group()/*:value, ' ')"/></value>
        <xsl:sequence select="current-group()[1]/*:unit"/>
        <xsl:sequence select="current-group()/*:address"/>
      </with-quantity>
    </xsl:for-each-group>
    <with-material-id xmlns="http://le-tex.de/ns/SemEx">
      <number>
        <xsl:value-of select="$context/ancestor::*:table[1]
                              //*:quantity[@*:name eq 'werkstoffnummer']
                                          [ancestor::*[local-name()=$quantity-lookup-elements][1]
                                                      [xs:integer(@data-rownum) eq xs:integer($elt/@data-rownum)]
                                          ]/*:value"/>
      </number>
      <label>
        <xsl:value-of select="$context/ancestor::*:table[1]
                              //*:quantity[@*:name eq 'bezeichnung']
                                          [ancestor::*[local-name()=$quantity-lookup-elements][1]
                                                      [xs:integer(@data-rownum) eq xs:integer($elt/@data-rownum)]
                                          ]/*:value"/>
      </label>
    </with-material-id>
  </xsl:function>
  
  
</xsl:stylesheet>