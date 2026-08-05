<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003" DefaultTargets="Build" ToolsVersion="4.0">
  <PropertyGroup>
    <OutputType>Library</OutputType>
    <AssemblyName>RemObjects.Script</AssemblyName>
    <AllowGlobals>False</AllowGlobals>
    <AllowLegacyOutParams>False</AllowLegacyOutParams>
    <AllowLegacyCreate>False</AllowLegacyCreate>
    <Configuration Condition="'$(Configuration)' == ''">Release</Configuration>
    <ProjectGuid>{CAF9C919-D826-4452-910E-D8BA4861CD72}</ProjectGuid>
    <RootNamespace>RemObjects.Script</RootNamespace>
    <Company>RemObjects Software, Inc.</Company>
    <Mode>Echoes</Mode>
    <TargetFramework>.NETCore10.0</TargetFramework>
    <OutputPath>..\..\..\Bin\Build\$(Configuration)\Core</OutputPath>
  </PropertyGroup>
  <PropertyGroup Condition=" '$(Configuration)' == 'Debug' ">
    <DefineConstants>DEBUG;TRACE;</DefineConstants>
    <Optimize>False</Optimize>
    <GeneratePDB>True</GeneratePDB>
    <WarnOnCaseMismatch>True</WarnOnCaseMismatch>
  </PropertyGroup>
  <PropertyGroup Condition=" '$(Configuration)' == 'Release' ">
    <Optimize>True</Optimize>
    <GeneratePDB>True</GeneratePDB>
    <WarnOnCaseMismatch>True</WarnOnCaseMismatch>
  </PropertyGroup>
  <ItemGroup>
    <Compile Include="Common.pas" />
    <Compile Include="EcmaScript\Bindings\AdditiveOperators.pas" />
    <Compile Include="EcmaScript\Bindings\BitwiseOperators.pas" />
    <Compile Include="EcmaScript\Bindings\MultiplicativeOperators.pas" />
    <Compile Include="EcmaScript\Bindings\Operators.pas" />
    <Compile Include="EcmaScript\Bindings\PrePostfixOperators.pas" />
    <Compile Include="EcmaScript\Bindings\RelationalOperators.pas" />
    <Compile Include="EcmaScript\Bindings\ShiftOperators.pas" />
    <Compile Include="EcmaScript\Bindings\UnaryOperators.pas" />
    <Compile Include="EcmaScript\LanguageContext.pas" />
    <Compile Include="EcmaScript\Objects\Argument.pas" />
    <Compile Include="EcmaScript\Objects\Array.pas" />
    <Compile Include="EcmaScript\Objects\Boolean.pas" />
    <Compile Include="EcmaScript\Objects\Date.pas" />
    <Compile Include="EcmaScript\Objects\Debug.pas" />
    <Compile Include="EcmaScript\Objects\DefaultObjects.pas" />
    <Compile Include="EcmaScript\Objects\Error.pas" />
    <Compile Include="EcmaScript\Objects\Function.pas" />
    <Compile Include="EcmaScript\Objects\JSON.pas" />
    <Compile Include="EcmaScript\Objects\Math.pas" />
    <Compile Include="EcmaScript\Objects\Number.pas" />
    <Compile Include="EcmaScript\Objects\Object.pas" />
    <Compile Include="EcmaScript\Objects\RegExp.pas" />
    <Compile Include="EcmaScript\Objects\String.pas" />
    <Compile Include="EcmaScript\Objects\Utilities.pas" />
    <Compile Include="EcmaScript\Parser.pas" />
    <Compile Include="EcmaScript\ParserClasses.pas" />
    <Compile Include="EcmaScript\Scope.pas" />
    <Compile Include="EcmaScript\Tokenizer.pas" />
    <None Include="PascalScript\LanguageContext.pas" />
    <Compile Include="EcmaScript\Wrappers.pas" />
    <Compile Include="PascalScript\Parser.pas" />
    <Compile Include="PascalScript\ParserClasses.pas" />
    <Compile Include="PascalScript\Tokenizer.pas" />
    <Compile Include="Properties\AssemblyInfo.pas" />
    <EmbeddedResource Include="Properties\Resources.resx">
      <Generator>ResXFileCodeGenerator</Generator>
    </EmbeddedResource>
    <Compile Include="Properties\Resources.Designer.pas" />
    <Compile Include="ScriptComponent.pas">
      <CopyToOutputDirectory>Never</CopyToOutputDirectory>
    </Compile>
  </ItemGroup>
  <ItemGroup>
    <Folder Include="EcmaScript\" />
    <Folder Include="EcmaScript\Bindings\" />
    <Folder Include="EcmaScript\Objects\" />
    <Folder Include="PascalScript\" />
    <Folder Include="Properties\" />
  </ItemGroup>
  <Import Project="$(MSBuildExtensionsPath)\RemObjects Software\Elements\RemObjects.Elements.Echoes.targets" />
</Project>
