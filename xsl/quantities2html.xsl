<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xs" 
  version="2.0" xpath-default-namespace="http://www.w3.org/1999/xhtml">
  
  <xsl:variable name="table-head" select="collection()[2]"/>
  
  <xsl:template name="main">
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <meta charset="UTF-8"/>
        <style>
          td, th { border: 1px solid black }
          td.marked { background-color: #FFFF00; }
        </style>        
      </head>
      <body>
        <table class="quantities">
          <thead>
            <tr>
              <xsl:sequence select="$table-head//*:th"/>
            </tr>
          </thead>
          <tbody>
            <xsl:for-each-group select="/*:data/*:quantity" group-by="string-join((*:with-material-id, @name, *:address/*:tab-id),'')">
              <xsl:for-each select="current-group()">                
                <xsl:variable name="quantity" as="node()" select="."/>
                <xsl:variable name="quantity_new" as="element()+">
                  <xsl:copy>
                    <xsl:copy-of select="@*, node() except *:with-quantity[@*:name = $min-max-elements]"/>
                    <xsl:for-each select="descendant-or-self::*[@*:name = $min-max-elements]/*[local-name() = ('min-value', 'max-value')]">
                      <with-quantity name="{concat(parent::*/@*:name, '_', substring-before(local-name(), '-value'))}">
                        <value><xsl:value-of select="."/></value>
                      </with-quantity>
                    </xsl:for-each>
                    <xsl:for-each select="*:notes">
                      <with-quantity name="{concat(replace(parent::*/@*:name, '_(min|max)', ''), '_bemerkung')}">
                        <value><xsl:value-of select="string-join(*, '&#xa;')"/></value>
                      </with-quantity>
                    </xsl:for-each>
                    <xsl:for-each select="for $t in tokenize(current-group()[1]/@*:secondary-quantities, '\s') 
                                            return $t[not(exists(current-group()/*:with-quantity[@*:name eq $t]))]">
                      <with-quantity name="{concat(., '_missing')}">
                        <value>UNBEKANNT</value>
                      </with-quantity>
                    </xsl:for-each>
                  </xsl:copy>
                </xsl:variable>                
                <!--<xsl:message>***********************</xsl:message>
                <xsl:message select="$quantity_new"/>-->
                <xsl:for-each select="$quantity_new">
                  <tr>
                    <xsl:apply-templates select="$table-head//*:th" mode="insert-quantity-line">
                      <xsl:with-param name="quantity" as="element()" select="."/>
                    </xsl:apply-templates>
                  </tr>
                </xsl:for-each>
              </xsl:for-each>
              <tr>
                <xsl:for-each select="1 to count($table-head//*:th)">
                  <td><xsl:comment>empty</xsl:comment></td>
                </xsl:for-each>
              </tr>
            </xsl:for-each-group>
          </tbody>
        </table>
      </body>
    </html>
  </xsl:template>
  
  
  <xsl:template match="*:th" mode="insert-quantity-line">
    <xsl:param name="quantity" as="element()"/>
    <xsl:variable name="th-id" as="xs:string" select="@id"/>
    <td xmlns="http://www.w3.org/1999/xhtml" class="{$th-id}">
      <xsl:copy-of select="@* except (@id, @class)"/>
      <xsl:for-each select="$quantity/descendant-or-self::*[@*:name eq concat($th-id, '_missing')]">
        <xsl:attribute name="class" select="concat($th-id, ' marked')"/>
        <xsl:value-of select="*:value"/>
      </xsl:for-each>
      <xsl:for-each select="$quantity/descendant-or-self::*[@*:name eq $th-id]">
        <xsl:value-of select="replace(*:value, 
                                      if ($th-id = $remove-gt) then '[&#x3e;]\s?' else
                                      if ($th-id = $remove-le) then '[&#x2264;]\s?' else
                                      if ($th-id = $remove-plus) then '[&#x2b;]\s?' else 
                                      '^\s', 
                                      '')"/>
      </xsl:for-each>
    </td>
  </xsl:template>
  

  <xsl:template match="*:th[@id = $element-name-lookup]" mode="insert-quantity-line">
    <xsl:param name="quantity" as="element()"/>
    <xsl:variable name="th-id" as="xs:string" select="@id"/>
    <td xmlns="http://www.w3.org/1999/xhtml" class="{$th-id}">
      <xsl:copy-of select="@* except (@id, @class)"/>
      <xsl:value-of select="distinct-values($quantity//*[local-name() eq $th-id])"/>
    </td>
  </xsl:template>
  
  
  
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  
  <xsl:variable name="element-name-lookup" as="xs:string+" 
    select="'number', 'label', 'std-number', 'std-date', 'tab-id', 'title_de', 'title_en'"/>
  
  <xsl:variable name="min-max-elements" as="xs:string+" 
    select="'nennmass', 'waermebehandlung', 'zugfestigkeit'"/>
  
  <xsl:variable name="remove-gt" as="xs:string+" select="'nennmass_min'"/>
  <xsl:variable name="remove-le" as="xs:string+" select="'nennmass_max'"/>
  <xsl:variable name="remove-plus" as="xs:string+" select="'temperatur'"/>

  
</xsl:stylesheet>