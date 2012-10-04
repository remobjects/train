<?xml version="1.0" encoding="utf-8"?>
<Project DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003" ToolsVersion="4.0">
  <PropertyGroup>
    <ProductVersion>3.5</ProductVersion>
    <RootNamespace>RemObjects.Train</RootNamespace>
    <StartupClass />
    <OutputType>Library</OutputType>
    <AssemblyName>RemObjects.Train</AssemblyName>
    <AllowGlobals>False</AllowGlobals>
    <AllowLegacyWith>False</AllowLegacyWith>
    <AllowLegacyOutParams>False</AllowLegacyOutParams>
    <AllowLegacyCreate>False</AllowLegacyCreate>
    <AllowUnsafeCode>False</AllowUnsafeCode>
    <ApplicationIcon>..\GtkTrain\Properties\App.ico</ApplicationIcon>
    <Configuration Condition="'$(Configuration)' == ''">Release</Configuration>
    <TargetFrameworkVersion>v4.0</TargetFrameworkVersion>
    <Name>RemObjects.Builder</Name>
    <ProjectGuid>{7e8ca883-87a3-4c65-9fef-c46b1c763bcb}</ProjectGuid>
    <DefaultUses />
    <InternalAssemblyName />
    <TargetFrameworkProfile />
  </PropertyGroup>
  <PropertyGroup Condition=" '$(Configuration)' == 'Debug' ">
    <Optimize>False</Optimize>
    <OutputPath>bin\Debug\</OutputPath>
    <DefineConstants>DEBUG;TRACE;</DefineConstants>
    <GeneratePDB>True</GeneratePDB>
    <GenerateMDB>True</GenerateMDB>
    <StartMode>Project</StartMode>
    <CpuType>anycpu</CpuType>
    <RuntimeVersion>v25</RuntimeVersion>
    <XmlDoc>False</XmlDoc>
    <XmlDocWarningLevel>WarningOnPublicMembers</XmlDocWarningLevel>
    <EnableUnmanagedDebugging>False</EnableUnmanagedDebugging>
    <SuppressWarnings />
    <FutureHelperClassName />
    <DebugClass />
    <AssertMethodName />
    <WarnOnCaseMismatch>True</WarnOnCaseMismatch>
  </PropertyGroup>
  <PropertyGroup Condition=" '$(Configuration)' == 'Release' ">
    <Optimize>true</Optimize>
    <OutputPath>.\bin\Release</OutputPath>
    <GeneratePDB>False</GeneratePDB>
    <GenerateMDB>False</GenerateMDB>
    <EnableAsserts>False</EnableAsserts>
    <TreatWarningsAsErrors>False</TreatWarningsAsErrors>
    <CaptureConsoleOutput>False</CaptureConsoleOutput>
    <StartMode>Project</StartMode>
    <RegisterForComInterop>False</RegisterForComInterop>
    <CpuType>anycpu</CpuType>
    <RuntimeVersion>v25</RuntimeVersion>
    <XmlDoc>False</XmlDoc>
    <XmlDocWarningLevel>WarningOnPublicMembers</XmlDocWarningLevel>
    <EnableUnmanagedDebugging>False</EnableUnmanagedDebugging>
    <WarnOnCaseMismatch>True</WarnOnCaseMismatch>
  </PropertyGroup>
  <ItemGroup>
    <Reference Include="DiscUtils">
      <HintPath>Libraries\DiscUtils.dll</HintPath>
    </Reference>
    <Reference Include="Ionic.Zip">
      <HintPath>Libraries\Ionic.Zip.dll</HintPath>
    </Reference>
    <Reference Include="mscorlib" />
    <Reference Include="Renci.SshNet">
      <HintPath>Libraries\Renci.SshNet.dll</HintPath>
    </Reference>
    <Reference Include="System" />
    <Reference Include="System.Data" />
    <Reference Include="System.Xml" />
    <Reference Include="System.Core">
      <RequiredTargetFramework>3.5</RequiredTargetFramework>
    </Reference>
    <Reference Include="System.Xml.Linq">
      <RequiredTargetFramework>3.5</RequiredTargetFramework>
    </Reference>
    <Reference Include="System.Data.DataSetExtensions">
      <RequiredTargetFramework>3.5</RequiredTargetFramework>
    </Reference>
  </ItemGroup>
  <ItemGroup>
    <Compile Include="API\Async.pas" />
    <Compile Include="API\Delphi.pas" />
    <Compile Include="API\Environment.pas" />
    <Compile Include="API\File.pas" />
    <Compile Include="API\FTP.pas" />
    <Compile Include="API\Gac.pas" />
    <Compile Include="API\Images.pas" />
    <Compile Include="API\Ini.pas" />
    <Compile Include="API\InnoSetup.pas" />
    <Compile Include="API\Interfaces.pas" />
    <Compile Include="API\Logging.pas" />
    <Compile Include="API\Mail.pas" />
    <Compile Include="API\MD5.pas" />
    <Compile Include="API\MSBuild.pas" />
    <Compile Include="API\NUnit.pas" />
    <Compile Include="API\Resources.pas" />
    <Compile Include="API\Shell.pas" />
    <Compile Include="API\SSH.pas" />
    <Compile Include="API\Web.pas" />
    <Compile Include="API\Wrapper.pas" />
    <Compile Include="API\Xcode.pas" />
    <Compile Include="API\XML.pas" />
    <Compile Include="API\Zip.pas" />
    <Compile Include="DelayedLogger.pas" />
    <Compile Include="Engine.pas" />
    <Compile Include="Ini.pas" />
    <Compile Include="Properties\AssemblyInfo.pas" />
    <Compile Include="Utilities.pas" />
    <EmbeddedResource Include="Properties\Resources.resx">
      <Generator>ResXFileCodeGenerator</Generator>
    </EmbeddedResource>
    <Compile Include="Properties\Resources.Designer.pas" />
    <None Include="Properties\Settings.settings">
      <Generator>SettingsSingleFileGenerator</Generator>
    </None>
    <Compile Include="Properties\Settings.Designer.pas" />
  </ItemGroup>
  <ItemGroup>
    <Folder Include="API" />
    <Folder Include="Properties\" />
    <Folder Include="Resources\" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\Script\Source\RemObjects.Script\RemObjects.Script.oxygene">
      <Name>RemObjects.Script</Name>
      <Project>{caf9c919-d826-4452-910e-d8ba4861cd72}</Project>
      <Private>True</Private>
      <HintPath>..\Script\Source\RemObjects.Script\..\..\Bin\RemObjects.Script.dll</HintPath>
    </ProjectReference>
  </ItemGroup>
  <ItemGroup>
    <EmbeddedResource Include="Resources\Train2HTML.xslt">
      <SubType>Content</SubType>
    </EmbeddedResource>
  </ItemGroup>
  <Import Project="$(MSBuildExtensionsPath)\RemObjects Software\Oxygene\RemObjects.Oxygene.targets" />
  <PropertyGroup>
    <PreBuildEvent>
    </PreBuildEvent>
  </PropertyGroup>
</Project>