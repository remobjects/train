<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="html"/>

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
        <xsl:value-of select="@name" /><span class="args">(<xsl:value-of select="@args" />)</span>
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
          x.action .toggle { display: none; }
          x.action .args { display: none; }
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
              <a href="http://remobjects.com/train"><b>RemObjects Train</b></a> &#8212; log file for <xsl:value-of select="/log/action/@args" />
            </td>
           </tr>
          <xsl:for-each select="action">
           <xsl:apply-templates />
          </xsl:for-each>  
        </table>
      </body>
    </html>
  </xsl:template>

</xsl:stylesheet>

  <!--
  

            <xsl:for-each select="log">
              <xsl:for-each select="*">
                <xsl:for-each select="Tests">
                  <xsl:for-each select="Test">
                    
                    <xsl:if test="result='0'">
                      <tr class="output" style="visibility:hidden; display:none;">
                        <xsl:attribute name="id">tr_<xsl:value-of select="generate-id(.)"/></xsl:attribute>
                        <td width="50"></td>
                        <td colspan="2">
                          <pre>
                            <xsl:value-of select="Output" />
                          </pre>
                        </td>
                      </tr>
                    </xsl:if>

                    <xsl:for-each select="Tasks">
                      <xsl:for-each select="Task">
                        <tr class="task">
                          <xsl:if test="@result='0'">
                            <xsl:attribute name="class">task-failed</xsl:attribute>
                          </xsl:if>
                          <xsl:if test="@result='1'">
                            <xsl:attribute name="class">task-succeeded</xsl:attribute>
                          </xsl:if>
                          <td>
                            <xsl:if test="@result='1'">
                              TASK
                            </xsl:if>
                            <xsl:if test="@result='0'">
                              <a href="javascript:toggle('{generate-id(.)}');">TASK</a>
                            </xsl:if>
                          </td>
                          <td>
                            <xsl:value-of select="@Name" />
                          </td>
                          <td>
                            <xsl:if test="@result='0'">
                              FAILED
                            </xsl:if>
                            <xsl:if test="@result='true'">
                              SUCCEEDED
                            </xsl:if>
                          </td>
                        </tr>
                        <xsl:if test="@result='0'">
                          <tr class="output" style="visibility:hidden; display:none;">
                            <xsl:attribute name="id">tr_<xsl:value-of select="generate-id(.)"/></xsl:attribute>
                            <td width="50"></td>
                            <td colspan="2">
                              <pre>
                                <xsl:value-of select="." />
                              </pre>
                            </td>
                          </tr>
                        </xsl:if>
                      </xsl:for-each>
                    </xsl:for-each>

                  </xsl:for-each>
                </xsl:for-each>
              </xsl:for-each>
            </xsl:for-each>
            
            -->