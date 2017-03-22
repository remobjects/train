<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="html"/>

  <xsl:template match="errors">
    <tr class="error-summary">
      <td colspan="2" class="error-summary">
        <b>Error Summary:</b><br />
        <table cellspacing="0" cellpadding="5" width="100%">
          <xsl:apply-templates />
        </table>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="message">
    <tr class="message">
      <td width="10">
      </td>
      <td width="*">
        <pre>
          <xsl:value-of select="." />
        </pre>
      </td>
    </tr>
  </xsl:template>
  <xsl:template match="error">
    <tr class="error">
      <td width="10">
      </td>
      <td width="*">
        <pre>
          <xsl:value-of select="." />
        </pre>
      </td>
    </tr>
  </xsl:template>
  <xsl:template match="return">
    <tr class="return">
      <td width="10">
      </td>
      <td width="*">
        <pre>
          <xsl:value-of select="." />
        </pre>
      </td>
    </tr>
  </xsl:template>
  
  <xsl:template match="action">
    <tr class="action">
      <xsl:if test="@result='0'">
        <xsl:attribute name="class">action-failed</xsl:attribute>
      </xsl:if>
      <xsl:if test="@result='1'">
        <xsl:attribute name="class">action-succeeded</xsl:attribute>
      </xsl:if>
      <td width="10">
        <xsl:if test="action|message">
          <a class="toggle" href="javascript:toggle('{generate-id(.)}');">[&#8597;]</a>
        </xsl:if>
      </td>
      <td width="*">
        <div><xsl:value-of select="@name" /><span class="args">(<xsl:value-of select="@args" />)</span>&#160;<span class="took">(took <xsl:value-of select="@took" />)</span></div>
      </td>
    </tr>
    <tr class="output" style="visibility: hidden; display:none;">
      <xsl:attribute name="id">tr_<xsl:value-of select="generate-id(.)"/></xsl:attribute>
      <xsl:if test="@result='0'">
        <xsl:attribute name="style">visibility: visible; display: table-row;</xsl:attribute>
        <xsl:attribute name="class">output-failed</xsl:attribute>
      </xsl:if>  
      <xsl:if test="@result='1'">
        <xsl:attribute name="class">output-succeeded</xsl:attribute>
      </xsl:if>
      <td width="10"></td>
      <td width="*">
        <table cellspacing="0" cellpadding="5" width="100%">
          <xsl:for-each select=".">
            <xsl:apply-templates />
          </xsl:for-each>
        </table>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="/log">
    <html>
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <style>
          body, table {font-family: Segoe UI; font-size: 9pt; margin: 0; padding: 0; }
          tr.header { background-color: #e0e0ff; color: #808080; }
          tr.header b { color: #202080; }
          tr.action { color: #808080; }
          tr.action-failed {background-color: #ffe0e0;}
          tr.action-succeeded {background-color: #e0ffe0;}
          tr.output-failed {background-color: #ffe0e0;}
          tr.output-succeeded {background-color: #e0ffe0;}
          tr.message { font-weight: bold; background-color: white; }
          tr.error { font-weight: bold; background-color: #ffe0e0; }
          tr.return { font-weight: bold; background-color: #ffffe0; }
          td.error-summary { border: 5px solid #800000; background-color: #ffe0e0; }
          x.action .toggle { display: none; }
          x.action .args { display: none; }
          .took { color: #808080; }
          a { color: #404040; text-decoration: none; }
        </style>
      </head>
      <body>
        <script language="JavaScript">
          function toggle(id)
          {
            element = document.getElementById("tr_"+id).style;
            if(element.visibility == "hidden")
            {
              element.visibility = "visible";
              element.display = "table-row";
            }
            else
            {
              element.visibility = "hidden";
              element.display = "none";
            }
          }
        </script>
        <table cellspacing="0" cellpadding="5" width="100%">
          <tr class="header">
            <td>
            </td>
            <td>
              <a href="http://remobjects.com/train"><b>RemObjects Train</b></a> — log file for <xsl:value-of select="/log/action/@args" />
            </td>
           </tr>
           <xsl:apply-templates />
        </table>
      </body>
    </html>
  </xsl:template>

</xsl:stylesheet>