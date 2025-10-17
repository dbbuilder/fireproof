USE [FireProofDB]
GO
/****** Object:  Table [dbo].[AuditLog]    Script Date: 10/17/2025 3:11:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AuditLog](
	[AuditLogId] [bigint] IDENTITY(1,1) NOT NULL,
	[TenantId] [uniqueidentifier] NOT NULL,
	[UserId] [uniqueidentifier] NULL,
	[Action] [nvarchar](100) NOT NULL,
	[EntityType] [nvarchar](100) NULL,
	[EntityId] [nvarchar](128) NULL,
	[OldValues] [nvarchar](max) NULL,
	[NewValues] [nvarchar](max) NULL,
	[IpAddress] [nvarchar](45) NULL,
	[UserAgent] [nvarchar](500) NULL,
	[Timestamp] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_AuditLog] PRIMARY KEY CLUSTERED 
(
	[AuditLogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ChecklistItems]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChecklistItems](
	[ChecklistItemId] [uniqueidentifier] NOT NULL,
	[TemplateId] [uniqueidentifier] NOT NULL,
	[ItemText] [nvarchar](500) NOT NULL,
	[ItemDescription] [nvarchar](1000) NULL,
	[Order] [int] NOT NULL,
	[Category] [nvarchar](50) NOT NULL,
	[Required] [bit] NOT NULL,
	[RequiresPhoto] [bit] NOT NULL,
	[RequiresComment] [bit] NOT NULL,
	[PassFailNA] [bit] NOT NULL,
	[VisualAid] [nvarchar](500) NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ChecklistItemId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ChecklistTemplates]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChecklistTemplates](
	[TemplateId] [uniqueidentifier] NOT NULL,
	[TenantId] [uniqueidentifier] NULL,
	[TemplateName] [nvarchar](200) NOT NULL,
	[InspectionType] [nvarchar](50) NOT NULL,
	[Standard] [nvarchar](50) NOT NULL,
	[IsSystemTemplate] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Description] [nvarchar](1000) NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[ModifiedDate] [datetime2](7) NULL,
PRIMARY KEY CLUSTERED 
(
	[TemplateId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Extinguishers]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Extinguishers](
	[ExtinguisherId] [uniqueidentifier] NOT NULL,
	[TenantId] [uniqueidentifier] NOT NULL,
	[LocationId] [uniqueidentifier] NOT NULL,
	[ExtinguisherTypeId] [uniqueidentifier] NOT NULL,
	[AssetTag] [nvarchar](100) NOT NULL,
	[BarcodeData] [nvarchar](500) NULL,
	[Manufacturer] [nvarchar](200) NULL,
	[Model] [nvarchar](200) NULL,
	[SerialNumber] [nvarchar](200) NULL,
	[ManufactureDate] [date] NULL,
	[InstallDate] [date] NULL,
	[LastHydrostaticTestDate] [date] NULL,
	[Capacity] [nvarchar](50) NULL,
	[LocationDescription] [nvarchar](500) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[ModifiedDate] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ExtinguisherId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Extinguishers_TenantAssetTag] UNIQUE NONCLUSTERED 
(
	[TenantId] ASC,
	[AssetTag] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ExtinguisherTypes]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ExtinguisherTypes](
	[ExtinguisherTypeId] [uniqueidentifier] NOT NULL,
	[TypeCode] [nvarchar](50) NOT NULL,
	[TypeName] [nvarchar](200) NOT NULL,
	[Description] [nvarchar](max) NULL,
	[MonthlyInspectionRequired] [bit] NOT NULL,
	[AnnualInspectionRequired] [bit] NOT NULL,
	[HydrostaticTestYears] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ExtinguisherTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[TypeCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[InspectionChecklistResponses]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InspectionChecklistResponses](
	[ResponseId] [uniqueidentifier] NOT NULL,
	[InspectionId] [uniqueidentifier] NOT NULL,
	[ChecklistItemId] [uniqueidentifier] NOT NULL,
	[Response] [nvarchar](10) NOT NULL,
	[Comment] [nvarchar](1000) NULL,
	[PhotoId] [uniqueidentifier] NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ResponseId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[InspectionChecklistTemplates]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InspectionChecklistTemplates](
	[ChecklistTemplateId] [uniqueidentifier] NOT NULL,
	[TenantId] [uniqueidentifier] NOT NULL,
	[InspectionTypeId] [uniqueidentifier] NOT NULL,
	[TemplateName] [nvarchar](200) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_tenant_60C74CCA6CD0490193D472F3EFFF38B5_ChecklistTemplates] PRIMARY KEY CLUSTERED 
(
	[ChecklistTemplateId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[InspectionDeficiencies]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InspectionDeficiencies](
	[DeficiencyId] [uniqueidentifier] NOT NULL,
	[InspectionId] [uniqueidentifier] NOT NULL,
	[DeficiencyType] [nvarchar](50) NOT NULL,
	[Severity] [nvarchar](20) NOT NULL,
	[Description] [nvarchar](1000) NOT NULL,
	[Status] [nvarchar](20) NOT NULL,
	[ActionRequired] [nvarchar](500) NULL,
	[EstimatedCost] [decimal](10, 2) NULL,
	[AssignedToUserId] [uniqueidentifier] NULL,
	[DueDate] [date] NULL,
	[ResolutionNotes] [nvarchar](1000) NULL,
	[ResolvedDate] [datetime2](7) NULL,
	[ResolvedByUserId] [uniqueidentifier] NULL,
	[PhotoIds] [nvarchar](max) NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[ModifiedDate] [datetime2](7) NULL,
PRIMARY KEY CLUSTERED 
(
	[DeficiencyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[InspectionPhotos]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InspectionPhotos](
	[PhotoId] [uniqueidentifier] NOT NULL,
	[InspectionId] [uniqueidentifier] NOT NULL,
	[PhotoType] [nvarchar](50) NOT NULL,
	[BlobUrl] [nvarchar](500) NOT NULL,
	[ThumbnailUrl] [nvarchar](500) NULL,
	[FileSize] [bigint] NULL,
	[MimeType] [nvarchar](100) NULL,
	[CaptureDate] [datetime2](7) NULL,
	[Latitude] [decimal](9, 6) NULL,
	[Longitude] [decimal](9, 6) NULL,
	[DeviceModel] [nvarchar](200) NULL,
	[EXIFData] [nvarchar](max) NULL,
	[Notes] [nvarchar](500) NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[PhotoId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Inspections]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Inspections](
	[InspectionId] [uniqueidentifier] NOT NULL,
	[TenantId] [uniqueidentifier] NOT NULL,
	[ExtinguisherId] [uniqueidentifier] NOT NULL,
	[InspectionTypeId] [uniqueidentifier] NOT NULL,
	[InspectorUserId] [uniqueidentifier] NOT NULL,
	[InspectionDate] [datetime2](7) NOT NULL,
	[Passed] [bit] NOT NULL,
	[IsAccessible] [bit] NOT NULL,
	[HasObstructions] [bit] NOT NULL,
	[SignageVisible] [bit] NOT NULL,
	[SealIntact] [bit] NULL,
	[PinInPlace] [bit] NULL,
	[NozzleClear] [bit] NULL,
	[HoseConditionGood] [bit] NULL,
	[GaugeInGreenZone] [bit] NULL,
	[GaugePressurePsi] [decimal](6, 2) NULL,
	[PhysicalDamagePresent] [bit] NOT NULL,
	[InspectionTagAttached] [bit] NOT NULL,
	[RequiresService] [bit] NOT NULL,
	[RequiresReplacement] [bit] NOT NULL,
	[Notes] [nvarchar](max) NULL,
	[FailureReason] [nvarchar](max) NULL,
	[CorrectiveAction] [nvarchar](max) NULL,
	[GpsLatitude] [decimal](10, 7) NULL,
	[GpsLongitude] [decimal](10, 7) NULL,
	[DeviceId] [nvarchar](200) NULL,
	[TamperProofHash] [nvarchar](100) NULL,
	[PreviousInspectionHash] [nvarchar](100) NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[InspectionType] [nvarchar](50) NULL,
	[GpsAccuracyMeters] [int] NULL,
	[LocationVerified] [bit] NOT NULL,
	[DamageDescription] [nvarchar](max) NULL,
	[WeightPounds] [decimal](10, 2) NULL,
	[WeightWithinSpec] [bit] NOT NULL,
	[PreviousInspectionDate] [nvarchar](50) NULL,
	[PhotoUrls] [nvarchar](max) NULL,
	[DataHash] [nvarchar](512) NULL,
	[InspectorSignature] [nvarchar](512) NULL,
	[SignedDate] [datetime2](7) NULL,
	[IsVerified] [bit] NOT NULL,
	[ModifiedDate] [datetime2](7) NULL,
PRIMARY KEY CLUSTERED 
(
	[InspectionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[InspectionTypes]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InspectionTypes](
	[InspectionTypeId] [uniqueidentifier] NOT NULL,
	[TenantId] [uniqueidentifier] NOT NULL,
	[TypeName] [nvarchar](200) NOT NULL,
	[Description] [nvarchar](max) NULL,
	[RequiresServiceTechnician] [bit] NOT NULL,
	[FrequencyDays] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[InspectionTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Locations]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Locations](
	[LocationId] [uniqueidentifier] NOT NULL,
	[TenantId] [uniqueidentifier] NOT NULL,
	[LocationCode] [nvarchar](50) NOT NULL,
	[LocationName] [nvarchar](200) NOT NULL,
	[AddressLine1] [nvarchar](200) NULL,
	[AddressLine2] [nvarchar](200) NULL,
	[City] [nvarchar](100) NULL,
	[StateProvince] [nvarchar](100) NULL,
	[PostalCode] [nvarchar](20) NULL,
	[Country] [nvarchar](100) NULL,
	[ContactName] [nvarchar](200) NULL,
	[ContactPhone] [nvarchar](50) NULL,
	[ContactEmail] [nvarchar](200) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[ModifiedDate] [datetime2](7) NOT NULL,
	[Latitude] [decimal](10, 7) NULL,
	[Longitude] [decimal](10, 7) NULL,
	[LocationBarcodeData] [nvarchar](500) NULL,
PRIMARY KEY CLUSTERED 
(
	[LocationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Locations_TenantCode] UNIQUE NONCLUSTERED 
(
	[TenantId] ASC,
	[LocationCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MaintenanceRecords]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MaintenanceRecords](
	[MaintenanceRecordId] [uniqueidentifier] NOT NULL,
	[ExtinguisherId] [uniqueidentifier] NOT NULL,
	[MaintenanceType] [nvarchar](100) NOT NULL,
	[MaintenanceDate] [date] NOT NULL,
	[TechnicianName] [nvarchar](200) NULL,
	[ServiceCompany] [nvarchar](200) NULL,
	[Cost] [decimal](10, 2) NULL,
	[Notes] [nvarchar](max) NULL,
	[ReceiptBlobPath] [nvarchar](500) NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_tenant_60C74CCA6CD0490193D472F3EFFF38B5_Maintenance] PRIMARY KEY CLUSTERED 
(
	[MaintenanceRecordId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SystemRoles]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SystemRoles](
	[SystemRoleId] [uniqueidentifier] NOT NULL,
	[RoleName] [nvarchar](50) NOT NULL,
	[Description] [nvarchar](500) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_SystemRoles] PRIMARY KEY CLUSTERED 
(
	[SystemRoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_SystemRoles_RoleName] UNIQUE NONCLUSTERED 
(
	[RoleName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Tenants]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tenants](
	[TenantId] [uniqueidentifier] NOT NULL,
	[TenantCode] [nvarchar](50) NOT NULL,
	[CompanyName] [nvarchar](200) NOT NULL,
	[SubscriptionTier] [nvarchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[MaxLocations] [int] NOT NULL,
	[MaxUsers] [int] NOT NULL,
	[MaxExtinguishers] [int] NOT NULL,
	[DatabaseSchema] [nvarchar](128) NOT NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[ModifiedDate] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_Tenants] PRIMARY KEY CLUSTERED 
(
	[TenantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Tenants_TenantCode] UNIQUE NONCLUSTERED 
(
	[TenantCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Users]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Users](
	[UserId] [uniqueidentifier] NOT NULL,
	[Email] [nvarchar](256) NOT NULL,
	[FirstName] [nvarchar](100) NOT NULL,
	[LastName] [nvarchar](100) NOT NULL,
	[AzureAdB2CObjectId] [nvarchar](128) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[ModifiedDate] [datetime2](7) NOT NULL,
	[PasswordHash] [nvarchar](500) NULL,
	[PasswordSalt] [nvarchar](500) NULL,
	[RefreshToken] [nvarchar](500) NULL,
	[RefreshTokenExpiryDate] [datetime2](7) NULL,
	[LastLoginDate] [datetime2](7) NULL,
	[EmailConfirmed] [bit] NOT NULL,
	[PhoneNumber] [nvarchar](20) NULL,
	[MfaEnabled] [bit] NOT NULL,
 CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UserSystemRoles]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserSystemRoles](
	[UserSystemRoleId] [uniqueidentifier] NOT NULL,
	[UserId] [uniqueidentifier] NOT NULL,
	[SystemRoleId] [uniqueidentifier] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_UserSystemRoles] PRIMARY KEY CLUSTERED 
(
	[UserSystemRoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_UserSystemRoles_User_Role] UNIQUE NONCLUSTERED 
(
	[UserId] ASC,
	[SystemRoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UserTenantRoles]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserTenantRoles](
	[UserTenantRoleId] [uniqueidentifier] NOT NULL,
	[UserId] [uniqueidentifier] NOT NULL,
	[TenantId] [uniqueidentifier] NOT NULL,
	[RoleName] [nvarchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_UserTenantRoles] PRIMARY KEY CLUSTERED 
(
	[UserTenantRoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[AuditLog] ADD  DEFAULT (getutcdate()) FOR [Timestamp]
GO
ALTER TABLE [dbo].[ChecklistItems] ADD  DEFAULT (newid()) FOR [ChecklistItemId]
GO
ALTER TABLE [dbo].[ChecklistItems] ADD  DEFAULT ((1)) FOR [Required]
GO
ALTER TABLE [dbo].[ChecklistItems] ADD  DEFAULT ((0)) FOR [RequiresPhoto]
GO
ALTER TABLE [dbo].[ChecklistItems] ADD  DEFAULT ((0)) FOR [RequiresComment]
GO
ALTER TABLE [dbo].[ChecklistItems] ADD  DEFAULT ((1)) FOR [PassFailNA]
GO
ALTER TABLE [dbo].[ChecklistItems] ADD  DEFAULT (getutcdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[ChecklistTemplates] ADD  DEFAULT (newid()) FOR [TemplateId]
GO
ALTER TABLE [dbo].[ChecklistTemplates] ADD  DEFAULT ((0)) FOR [IsSystemTemplate]
GO
ALTER TABLE [dbo].[ChecklistTemplates] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[ChecklistTemplates] ADD  DEFAULT (getutcdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[Extinguishers] ADD  DEFAULT (newid()) FOR [ExtinguisherId]
GO
ALTER TABLE [dbo].[Extinguishers] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Extinguishers] ADD  DEFAULT (getutcdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[Extinguishers] ADD  DEFAULT (getutcdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[ExtinguisherTypes] ADD  DEFAULT (newid()) FOR [ExtinguisherTypeId]
GO
ALTER TABLE [dbo].[ExtinguisherTypes] ADD  DEFAULT ((1)) FOR [MonthlyInspectionRequired]
GO
ALTER TABLE [dbo].[ExtinguisherTypes] ADD  DEFAULT ((1)) FOR [AnnualInspectionRequired]
GO
ALTER TABLE [dbo].[ExtinguisherTypes] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[ExtinguisherTypes] ADD  DEFAULT (getutcdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[InspectionChecklistResponses] ADD  DEFAULT (newid()) FOR [ResponseId]
GO
ALTER TABLE [dbo].[InspectionChecklistResponses] ADD  DEFAULT (getutcdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[InspectionChecklistTemplates] ADD  DEFAULT (newid()) FOR [ChecklistTemplateId]
GO
ALTER TABLE [dbo].[InspectionChecklistTemplates] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[InspectionChecklistTemplates] ADD  DEFAULT (getutcdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[InspectionDeficiencies] ADD  DEFAULT (newid()) FOR [DeficiencyId]
GO
ALTER TABLE [dbo].[InspectionDeficiencies] ADD  DEFAULT ('Open') FOR [Status]
GO
ALTER TABLE [dbo].[InspectionDeficiencies] ADD  DEFAULT (getutcdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[InspectionPhotos] ADD  DEFAULT (newid()) FOR [PhotoId]
GO
ALTER TABLE [dbo].[InspectionPhotos] ADD  DEFAULT (getutcdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[Inspections] ADD  DEFAULT (newid()) FOR [InspectionId]
GO
ALTER TABLE [dbo].[Inspections] ADD  DEFAULT ((1)) FOR [IsAccessible]
GO
ALTER TABLE [dbo].[Inspections] ADD  DEFAULT ((0)) FOR [HasObstructions]
GO
ALTER TABLE [dbo].[Inspections] ADD  DEFAULT ((1)) FOR [SignageVisible]
GO
ALTER TABLE [dbo].[Inspections] ADD  DEFAULT ((0)) FOR [PhysicalDamagePresent]
GO
ALTER TABLE [dbo].[Inspections] ADD  DEFAULT ((1)) FOR [InspectionTagAttached]
GO
ALTER TABLE [dbo].[Inspections] ADD  DEFAULT ((0)) FOR [RequiresService]
GO
ALTER TABLE [dbo].[Inspections] ADD  DEFAULT ((0)) FOR [RequiresReplacement]
GO
ALTER TABLE [dbo].[Inspections] ADD  DEFAULT (getutcdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[Inspections] ADD  DEFAULT ((0)) FOR [LocationVerified]
GO
ALTER TABLE [dbo].[Inspections] ADD  DEFAULT ((1)) FOR [WeightWithinSpec]
GO
ALTER TABLE [dbo].[Inspections] ADD  DEFAULT ((0)) FOR [IsVerified]
GO
ALTER TABLE [dbo].[Inspections] ADD  DEFAULT (getutcdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[InspectionTypes] ADD  DEFAULT (newid()) FOR [InspectionTypeId]
GO
ALTER TABLE [dbo].[InspectionTypes] ADD  DEFAULT ((0)) FOR [RequiresServiceTechnician]
GO
ALTER TABLE [dbo].[InspectionTypes] ADD  DEFAULT ((365)) FOR [FrequencyDays]
GO
ALTER TABLE [dbo].[InspectionTypes] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[InspectionTypes] ADD  DEFAULT (getutcdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[Locations] ADD  DEFAULT (newid()) FOR [LocationId]
GO
ALTER TABLE [dbo].[Locations] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Locations] ADD  DEFAULT (getutcdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[Locations] ADD  DEFAULT (getutcdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[MaintenanceRecords] ADD  DEFAULT (newid()) FOR [MaintenanceRecordId]
GO
ALTER TABLE [dbo].[MaintenanceRecords] ADD  DEFAULT (getutcdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[SystemRoles] ADD  DEFAULT (newid()) FOR [SystemRoleId]
GO
ALTER TABLE [dbo].[SystemRoles] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[SystemRoles] ADD  DEFAULT (getutcdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[Tenants] ADD  DEFAULT (newid()) FOR [TenantId]
GO
ALTER TABLE [dbo].[Tenants] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Tenants] ADD  DEFAULT ((10)) FOR [MaxLocations]
GO
ALTER TABLE [dbo].[Tenants] ADD  DEFAULT ((5)) FOR [MaxUsers]
GO
ALTER TABLE [dbo].[Tenants] ADD  DEFAULT ((100)) FOR [MaxExtinguishers]
GO
ALTER TABLE [dbo].[Tenants] ADD  DEFAULT (getutcdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[Tenants] ADD  DEFAULT (getutcdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[Users] ADD  DEFAULT (newid()) FOR [UserId]
GO
ALTER TABLE [dbo].[Users] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Users] ADD  DEFAULT (getutcdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[Users] ADD  DEFAULT (getutcdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[Users] ADD  DEFAULT ((0)) FOR [EmailConfirmed]
GO
ALTER TABLE [dbo].[Users] ADD  DEFAULT ((0)) FOR [MfaEnabled]
GO
ALTER TABLE [dbo].[UserSystemRoles] ADD  DEFAULT (newid()) FOR [UserSystemRoleId]
GO
ALTER TABLE [dbo].[UserSystemRoles] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[UserSystemRoles] ADD  DEFAULT (getutcdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[UserTenantRoles] ADD  DEFAULT (newid()) FOR [UserTenantRoleId]
GO
ALTER TABLE [dbo].[UserTenantRoles] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[UserTenantRoles] ADD  DEFAULT (getutcdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[ChecklistItems]  WITH CHECK ADD  CONSTRAINT [FK_ChecklistItems_Template] FOREIGN KEY([TemplateId])
REFERENCES [dbo].[ChecklistTemplates] ([TemplateId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ChecklistItems] CHECK CONSTRAINT [FK_ChecklistItems_Template]
GO
ALTER TABLE [dbo].[Extinguishers]  WITH CHECK ADD  CONSTRAINT [FK_Extinguishers_Locations] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([LocationId])
GO
ALTER TABLE [dbo].[Extinguishers] CHECK CONSTRAINT [FK_Extinguishers_Locations]
GO
ALTER TABLE [dbo].[Extinguishers]  WITH CHECK ADD  CONSTRAINT [FK_Extinguishers_Tenants] FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([TenantId])
GO
ALTER TABLE [dbo].[Extinguishers] CHECK CONSTRAINT [FK_Extinguishers_Tenants]
GO
ALTER TABLE [dbo].[Extinguishers]  WITH CHECK ADD  CONSTRAINT [FK_Extinguishers_Types] FOREIGN KEY([ExtinguisherTypeId])
REFERENCES [dbo].[ExtinguisherTypes] ([ExtinguisherTypeId])
GO
ALTER TABLE [dbo].[Extinguishers] CHECK CONSTRAINT [FK_Extinguishers_Types]
GO
ALTER TABLE [dbo].[Extinguishers]  WITH CHECK ADD  CONSTRAINT [FK_tenant_5827F83D_743D_422D_94D5_90665BDA3506_Ext_Loc] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([LocationId])
GO
ALTER TABLE [dbo].[Extinguishers] CHECK CONSTRAINT [FK_tenant_5827F83D_743D_422D_94D5_90665BDA3506_Ext_Loc]
GO
ALTER TABLE [dbo].[Extinguishers]  WITH CHECK ADD  CONSTRAINT [FK_tenant_5827F83D_743D_422D_94D5_90665BDA3506_Ext_Type] FOREIGN KEY([ExtinguisherTypeId])
REFERENCES [dbo].[ExtinguisherTypes] ([ExtinguisherTypeId])
GO
ALTER TABLE [dbo].[Extinguishers] CHECK CONSTRAINT [FK_tenant_5827F83D_743D_422D_94D5_90665BDA3506_Ext_Type]
GO
ALTER TABLE [dbo].[Extinguishers]  WITH CHECK ADD  CONSTRAINT [FK_tenant_60C74CCA6CD0490193D472F3EFFF38B5_Ext_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([LocationId])
GO
ALTER TABLE [dbo].[Extinguishers] CHECK CONSTRAINT [FK_tenant_60C74CCA6CD0490193D472F3EFFF38B5_Ext_Location]
GO
ALTER TABLE [dbo].[Extinguishers]  WITH CHECK ADD  CONSTRAINT [FK_tenant_60C74CCA6CD0490193D472F3EFFF38B5_Ext_Type] FOREIGN KEY([ExtinguisherTypeId])
REFERENCES [dbo].[ExtinguisherTypes] ([ExtinguisherTypeId])
GO
ALTER TABLE [dbo].[Extinguishers] CHECK CONSTRAINT [FK_tenant_60C74CCA6CD0490193D472F3EFFF38B5_Ext_Type]
GO
ALTER TABLE [dbo].[Extinguishers]  WITH CHECK ADD  CONSTRAINT [FK_tenant_634F2B52_D32A_46DD_A045_D158E793ADCB_Ext_Loc] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([LocationId])
GO
ALTER TABLE [dbo].[Extinguishers] CHECK CONSTRAINT [FK_tenant_634F2B52_D32A_46DD_A045_D158E793ADCB_Ext_Loc]
GO
ALTER TABLE [dbo].[Extinguishers]  WITH CHECK ADD  CONSTRAINT [FK_tenant_634F2B52_D32A_46DD_A045_D158E793ADCB_Ext_Type] FOREIGN KEY([ExtinguisherTypeId])
REFERENCES [dbo].[ExtinguisherTypes] ([ExtinguisherTypeId])
GO
ALTER TABLE [dbo].[Extinguishers] CHECK CONSTRAINT [FK_tenant_634F2B52_D32A_46DD_A045_D158E793ADCB_Ext_Type]
GO
ALTER TABLE [dbo].[InspectionChecklistResponses]  WITH CHECK ADD  CONSTRAINT [FK_InspectionChecklistResponses_ChecklistItem] FOREIGN KEY([ChecklistItemId])
REFERENCES [dbo].[ChecklistItems] ([ChecklistItemId])
GO
ALTER TABLE [dbo].[InspectionChecklistResponses] CHECK CONSTRAINT [FK_InspectionChecklistResponses_ChecklistItem]
GO
ALTER TABLE [dbo].[InspectionChecklistResponses]  WITH CHECK ADD  CONSTRAINT [FK_InspectionChecklistResponses_Inspection] FOREIGN KEY([InspectionId])
REFERENCES [dbo].[Inspections] ([InspectionId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[InspectionChecklistResponses] CHECK CONSTRAINT [FK_InspectionChecklistResponses_Inspection]
GO
ALTER TABLE [dbo].[InspectionChecklistTemplates]  WITH CHECK ADD  CONSTRAINT [FK_tenant_60C74CCA6CD0490193D472F3EFFF38B5_CheckTemp_InspType] FOREIGN KEY([InspectionTypeId])
REFERENCES [dbo].[InspectionTypes] ([InspectionTypeId])
GO
ALTER TABLE [dbo].[InspectionChecklistTemplates] CHECK CONSTRAINT [FK_tenant_60C74CCA6CD0490193D472F3EFFF38B5_CheckTemp_InspType]
GO
ALTER TABLE [dbo].[InspectionDeficiencies]  WITH CHECK ADD  CONSTRAINT [FK_InspectionDeficiencies_Inspection] FOREIGN KEY([InspectionId])
REFERENCES [dbo].[Inspections] ([InspectionId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[InspectionDeficiencies] CHECK CONSTRAINT [FK_InspectionDeficiencies_Inspection]
GO
ALTER TABLE [dbo].[InspectionPhotos]  WITH CHECK ADD  CONSTRAINT [FK_InspectionPhotos_Inspection] FOREIGN KEY([InspectionId])
REFERENCES [dbo].[Inspections] ([InspectionId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[InspectionPhotos] CHECK CONSTRAINT [FK_InspectionPhotos_Inspection]
GO
ALTER TABLE [dbo].[Inspections]  WITH CHECK ADD  CONSTRAINT [FK_Inspections_Extinguisher] FOREIGN KEY([ExtinguisherId])
REFERENCES [dbo].[Extinguishers] ([ExtinguisherId])
GO
ALTER TABLE [dbo].[Inspections] CHECK CONSTRAINT [FK_Inspections_Extinguisher]
GO
ALTER TABLE [dbo].[Inspections]  WITH CHECK ADD  CONSTRAINT [FK_Inspections_Extinguishers] FOREIGN KEY([ExtinguisherId])
REFERENCES [dbo].[Extinguishers] ([ExtinguisherId])
GO
ALTER TABLE [dbo].[Inspections] CHECK CONSTRAINT [FK_Inspections_Extinguishers]
GO
ALTER TABLE [dbo].[Inspections]  WITH CHECK ADD  CONSTRAINT [FK_Inspections_Inspectors] FOREIGN KEY([InspectorUserId])
REFERENCES [dbo].[Users] ([UserId])
GO
ALTER TABLE [dbo].[Inspections] CHECK CONSTRAINT [FK_Inspections_Inspectors]
GO
ALTER TABLE [dbo].[Inspections]  WITH CHECK ADD  CONSTRAINT [FK_Inspections_Tenants] FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([TenantId])
GO
ALTER TABLE [dbo].[Inspections] CHECK CONSTRAINT [FK_Inspections_Tenants]
GO
ALTER TABLE [dbo].[Inspections]  WITH CHECK ADD  CONSTRAINT [FK_Inspections_Types] FOREIGN KEY([InspectionTypeId])
REFERENCES [dbo].[InspectionTypes] ([InspectionTypeId])
GO
ALTER TABLE [dbo].[Inspections] CHECK CONSTRAINT [FK_Inspections_Types]
GO
ALTER TABLE [dbo].[Inspections]  WITH CHECK ADD  CONSTRAINT [FK_tenant_60C74CCA6CD0490193D472F3EFFF38B5_Insp_Extinguisher] FOREIGN KEY([ExtinguisherId])
REFERENCES [dbo].[Extinguishers] ([ExtinguisherId])
GO
ALTER TABLE [dbo].[Inspections] CHECK CONSTRAINT [FK_tenant_60C74CCA6CD0490193D472F3EFFF38B5_Insp_Extinguisher]
GO
ALTER TABLE [dbo].[Inspections]  WITH CHECK ADD  CONSTRAINT [FK_tenant_60C74CCA6CD0490193D472F3EFFF38B5_Insp_Type] FOREIGN KEY([InspectionTypeId])
REFERENCES [dbo].[InspectionTypes] ([InspectionTypeId])
GO
ALTER TABLE [dbo].[Inspections] CHECK CONSTRAINT [FK_tenant_60C74CCA6CD0490193D472F3EFFF38B5_Insp_Type]
GO
ALTER TABLE [dbo].[InspectionTypes]  WITH CHECK ADD  CONSTRAINT [FK_InspectionTypes_Tenants] FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([TenantId])
GO
ALTER TABLE [dbo].[InspectionTypes] CHECK CONSTRAINT [FK_InspectionTypes_Tenants]
GO
ALTER TABLE [dbo].[Locations]  WITH CHECK ADD  CONSTRAINT [FK_Locations_Tenants] FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([TenantId])
GO
ALTER TABLE [dbo].[Locations] CHECK CONSTRAINT [FK_Locations_Tenants]
GO
ALTER TABLE [dbo].[MaintenanceRecords]  WITH CHECK ADD  CONSTRAINT [FK_tenant_60C74CCA6CD0490193D472F3EFFF38B5_Maint_Extinguisher] FOREIGN KEY([ExtinguisherId])
REFERENCES [dbo].[Extinguishers] ([ExtinguisherId])
GO
ALTER TABLE [dbo].[MaintenanceRecords] CHECK CONSTRAINT [FK_tenant_60C74CCA6CD0490193D472F3EFFF38B5_Maint_Extinguisher]
GO
ALTER TABLE [dbo].[UserSystemRoles]  WITH CHECK ADD  CONSTRAINT [FK_UserSystemRoles_SystemRoles] FOREIGN KEY([SystemRoleId])
REFERENCES [dbo].[SystemRoles] ([SystemRoleId])
GO
ALTER TABLE [dbo].[UserSystemRoles] CHECK CONSTRAINT [FK_UserSystemRoles_SystemRoles]
GO
ALTER TABLE [dbo].[UserSystemRoles]  WITH CHECK ADD  CONSTRAINT [FK_UserSystemRoles_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([UserId])
GO
ALTER TABLE [dbo].[UserSystemRoles] CHECK CONSTRAINT [FK_UserSystemRoles_Users]
GO
ALTER TABLE [dbo].[UserTenantRoles]  WITH CHECK ADD  CONSTRAINT [FK_UserTenantRoles_Tenants] FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([TenantId])
GO
ALTER TABLE [dbo].[UserTenantRoles] CHECK CONSTRAINT [FK_UserTenantRoles_Tenants]
GO
ALTER TABLE [dbo].[UserTenantRoles]  WITH CHECK ADD  CONSTRAINT [FK_UserTenantRoles_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([UserId])
GO
ALTER TABLE [dbo].[UserTenantRoles] CHECK CONSTRAINT [FK_UserTenantRoles_Users]
GO
ALTER TABLE [dbo].[Tenants]  WITH CHECK ADD  CONSTRAINT [CK_Tenants_SubscriptionTier] CHECK  (([SubscriptionTier]='Premium' OR [SubscriptionTier]='Standard' OR [SubscriptionTier]='Free'))
GO
ALTER TABLE [dbo].[Tenants] CHECK CONSTRAINT [CK_Tenants_SubscriptionTier]
GO
ALTER TABLE [dbo].[UserTenantRoles]  WITH CHECK ADD  CONSTRAINT [CK_UserTenantRoles_RoleName] CHECK  (([RoleName]='Viewer' OR [RoleName]='Inspector' OR [RoleName]='LocationManager' OR [RoleName]='TenantAdmin'))
GO
ALTER TABLE [dbo].[UserTenantRoles] CHECK CONSTRAINT [CK_UserTenantRoles_RoleName]
GO
/****** Object:  StoredProcedure [dbo].[sp_SetupUserWithRole]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE   PROCEDURE [dbo].[sp_SetupUserWithRole]
    @Email NVARCHAR(256),
    @FirstName NVARCHAR(100),
    @LastName NVARCHAR(100),
    @PasswordHash NVARCHAR(MAX),
    @RoleName NVARCHAR(50) = 'SystemAdmin',
    @TenantId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @UserId UNIQUEIDENTIFIER
    DECLARE @SystemRoleId UNIQUEIDENTIFIER
    DECLARE @ErrorMsg NVARCHAR(500)
    
    BEGIN TRY
        BEGIN TRANSACTION
        
        -- Check if user already exists
        SELECT @UserId = UserId FROM Users WHERE Email = @Email
        
        IF @UserId IS NULL
        BEGIN
            -- Create new user
            SET @UserId = NEWID()
            
            INSERT INTO Users (UserId, Email, FirstName, LastName, PasswordHash, EmailConfirmed, MfaEnabled, IsActive, CreatedDate, ModifiedDate)
            VALUES (@UserId, @Email, @FirstName, @LastName, @PasswordHash, 0, 0, 1, GETUTCDATE(), GETUTCDATE())
            
            PRINT 'User created: ' + @Email
        END
        ELSE
        BEGIN
            PRINT 'User already exists: ' + @Email
        END
        
        -- Get the role ID
        SELECT @SystemRoleId = SystemRoleId FROM SystemRoles WHERE RoleName = @RoleName
        
        IF @SystemRoleId IS NULL
        BEGIN
            SET @ErrorMsg = 'Role not found: ' + @RoleName
            RAISERROR(@ErrorMsg, 16, 1)
        END
        
        -- Check if user already has this role
        IF NOT EXISTS (SELECT 1 FROM UserSystemRoles WHERE UserId = @UserId AND SystemRoleId = @SystemRoleId)
        BEGIN
            -- Assign system role
            INSERT INTO UserSystemRoles (UserSystemRoleId, UserId, SystemRoleId, IsActive, CreatedDate)
            VALUES (NEWID(), @UserId, @SystemRoleId, 1, GETUTCDATE())
            
            PRINT 'Role ' + @RoleName + ' assigned to user'
        END
        ELSE
        BEGIN
            PRINT 'User already has ' + @RoleName + ' role'
        END
        
        -- Return user info
        SELECT 
            u.UserId,
            u.Email,
            u.FirstName,
            u.LastName,
            r.RoleName,
            usr.IsActive AS RoleIsActive,
            u.IsActive AS UserIsActive,
            u.CreatedDate
        FROM Users u
        LEFT JOIN UserSystemRoles usr ON u.UserId = usr.UserId
        LEFT JOIN SystemRoles r ON usr.SystemRoleId = r.SystemRoleId
        WHERE u.UserId = @UserId
        
        COMMIT TRANSACTION
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
        DECLARE @ErrorState INT = ERROR_STATE()
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)
    END CATCH
END

GO
/****** Object:  StoredProcedure [dbo].[SQLObjectChangeLog_Notify]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [dbo].[SQLObjectChangeLog_Notify]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Subject NVARCHAR(255) = 'SQL CODE CHANGES -' + DB_Name();
    DECLARE @Body NVARCHAR(MAX);
    DECLARE @Recipient NVARCHAR(255) = 'sql@schoolvision.net';

    -- Check if there are any changes since the last time this procedure was executed
    DECLARE @Changes TABLE (
        SQLObjectSQLObjectChangeLogID INT,
        ObjectName NVARCHAR(255),
        SchemaName NVARCHAR(255),
        ObjectType NVARCHAR(50),
        LastModifiedDate DATETIME
    );

    INSERT INTO @Changes
    SELECT SQLObjectChangeLogID, ObjectName, SchemaName, ObjectType, LastModifiedDate
    FROM SQLObjectChangeLog
    WHERE DateNotified is null;  -- Assuming we run hourly. Modify as needed.

    IF EXISTS (SELECT 1 FROM @Changes)
    BEGIN
        SET @Body = 'The following SQL Server code objects have changed:' + CHAR(10) + CHAR(10);
        
        SELECT 
            SchemaName , ObjectName , ObjectType  LastModifiedDate 
			into #tmpChanges
        FROM @Changes;


        SELECT @Body = @Body + 
            ' ' + ObjectType + ':  ' + ObjectName +  ' (' + schemaname +') - Modified on: ' + 
            CAST(LastModifiedDate AS NVARCHAR) + CHAR(10)
        FROM @Changes order by ObjectType, ObjectName;

		declare @d int = -1;
        -- Send Email
        EXEC @d = msdb.dbo.sp_send_dbmail
            @profile_name = 'Main',  -- Assuming 'Main' is your mail profile
            @recipients = @Recipient,
            @subject = @Subject,
            @body = @Body;
		if @d > 0
			update SQLObjectChangeLog set DateNotified = getdate() where SQLObjectChangeLogID in (Select SQLObjectSQLObjectChangeLogID from @Changes)
    END
END
GO
/****** Object:  StoredProcedure [dbo].[SQLObjectChangeLog_Setup]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create    procedure [dbo].[SQLObjectChangeLog_Setup] AS
if not exists(select * From sysobjects where name = 'SQLObjectChangeLog')
begin
CREATE TABLE SQLObjectChangeLog (
    SQLObjectChangeLogID INT IDENTITY(1,1) PRIMARY KEY,
    ObjectName NVARCHAR(255),
    SchemaName NVARCHAR(255),
    ObjectType NVARCHAR(50),
    LastModifiedDate DATETIME,
    ObjectDefinition NVARCHAR(MAX),
    DateLogged DATETIME DEFAULT GETDATE(),
	DateNotified datetime, 
    HashValue AS CAST(HASHBYTES('SHA2_256', ObjectDefinition) AS VARBINARY(64)) PERSISTED
)

if not exists(select * From sysindexes where name = 'IX_SQLObjectChangeLog_SchemaObject')
begin
-- Create indexes to improve query performance
CREATE INDEX IX_SQLObjectChangeLog_SchemaObject ON SQLObjectChangeLog (SchemaName, ObjectName, ObjectType);
end

if not exists(select * From sysindexes where name = 'IX_SQLObjectChangeLog_DateLogged')
begin
CREATE INDEX IX_SQLObjectChangeLog_DateLogged ON SQLObjectChangeLog (DateLogged);
end


if not exists(select * From sysindexes where name = 'IX_SQLObjectChangeLog_HashValue')
begin
CREATE INDEX IX_SQLObjectChangeLog_HashValue ON SQLObjectChangeLog (HashValue);
end

Exec SQLObjectChangeLog_Track NULL
update SQLObjectChangeLog set DateNotified = getdate()

end

GO
/****** Object:  StoredProcedure [dbo].[SQLObjectChangeLog_Track]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[SQLObjectChangeLog_Track] @LastXDays int = 7
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ObjectName NVARCHAR(255);
    DECLARE @SchemaName NVARCHAR(255);
    DECLARE @ObjectType NVARCHAR(50);
    DECLARE @ObjectDefinition NVARCHAR(MAX);
    DECLARE @LastModifiedDate DATETIME;
    DECLARE @OldHashValue VARBINARY(64);

    -- Cursor to iterate through all relevant objects created or modified in the last 90 days
    DECLARE db_cursor CURSOR FOR
    SELECT 
        SCHEMA_NAME(o.schema_id) AS SchemaName,
        o.name AS ObjectName,
        o.type_desc AS ObjectType,
        o.modify_date AS LastModifiedDate,
        m.definition AS ObjectDefinition
    FROM sys.objects o
    JOIN sys.sql_modules m ON o.object_id = m.object_id
    WHERE o.type IN ('P', 'V', 'FN', 'TF', 'IF') -- Procedures, Views, Scalar/Inline/Multi-Statement Functions
    AND (@LastXDays is null or o.modify_date >= DATEADD(DAY, -1 * @LastXDays, GETDATE())) -- Limit to objects modified in the last 90 days

    OPEN db_cursor;

    FETCH NEXT FROM db_cursor INTO @SchemaName, @ObjectName, @ObjectType, @LastModifiedDate, @ObjectDefinition;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Retrieve the old hash value (if it exists)
        SELECT TOP 1 @OldHashValue = HashValue 
        FROM SQLObjectChangeLog
        WHERE ObjectName = @ObjectName AND SchemaName = @SchemaName AND ObjectType = @ObjectType
        ORDER BY DateLogged DESC;

        -- Compute new hash value for the object definition
        DECLARE @NewHashValue VARBINARY(64) = HASHBYTES('SHA2_256', @ObjectDefinition);

        -- If @OldHashValue is NULL, it means the object does not exist in the log
        IF @OldHashValue IS NULL
        BEGIN
            -- Insert new log entry if the object does not exist in the log
            INSERT INTO SQLObjectChangeLog (ObjectName, SchemaName, ObjectType, LastModifiedDate, ObjectDefinition)
            VALUES (@ObjectName, @SchemaName, @ObjectType, @LastModifiedDate, @ObjectDefinition);
        END
        ELSE IF @OldHashValue != @NewHashValue
        BEGIN
            -- Insert new log entry if the hash value has changed
            INSERT INTO SQLObjectChangeLog (ObjectName, SchemaName, ObjectType, LastModifiedDate, ObjectDefinition)
            VALUES (@ObjectName, @SchemaName, @ObjectType, @LastModifiedDate, @ObjectDefinition);
        END

        FETCH NEXT FROM db_cursor INTO @SchemaName, @ObjectName, @ObjectType, @LastModifiedDate, @ObjectDefinition;
    END

    CLOSE db_cursor;
    DEALLOCATE db_cursor;

END
GO
/****** Object:  StoredProcedure [dbo].[usp_AuditLog_GetByTenant]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_AuditLog_GetByTenant]
    @TenantId UNIQUEIDENTIFIER,
    @StartDate DATETIME2 = NULL,
    @EndDate DATETIME2 = NULL,
    @Action NVARCHAR(100) = NULL,
    @PageSize INT = 100,
    @PageNumber INT = 1
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        AuditLogId,
        TenantId,
        UserId,
        Action,
        EntityType,
        EntityId,
        OldValues,
        NewValues,
        IpAddress,
        UserAgent,
        Timestamp
    FROM dbo.AuditLog
    WHERE TenantId = @TenantId
    AND (@StartDate IS NULL OR Timestamp >= @StartDate)
    AND (@EndDate IS NULL OR Timestamp <= @EndDate)
    AND (@Action IS NULL OR Action = @Action)
    ORDER BY Timestamp DESC
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY
END

GO
/****** Object:  StoredProcedure [dbo].[usp_AuditLog_Insert]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_AuditLog_Insert]
    @TenantId UNIQUEIDENTIFIER,
    @UserId UNIQUEIDENTIFIER = NULL,
    @Action NVARCHAR(100),
    @EntityType NVARCHAR(100) = NULL,
    @EntityId NVARCHAR(128) = NULL,
    @OldValues NVARCHAR(MAX) = NULL,
    @NewValues NVARCHAR(MAX) = NULL,
    @IpAddress NVARCHAR(45) = NULL,
    @UserAgent NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON

    INSERT INTO dbo.AuditLog (
        TenantId, UserId, Action, EntityType, EntityId,
        OldValues, NewValues, IpAddress, UserAgent
    )
    VALUES (
        @TenantId, @UserId, @Action, @EntityType, @EntityId,
        @OldValues, @NewValues, @IpAddress, @UserAgent
    )

    SELECT 'SUCCESS' AS Status
END

GO
/****** Object:  StoredProcedure [dbo].[usp_ChecklistItem_CreateBatch]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_ChecklistItem_CreateBatch]
      @TemplateId UNIQUEIDENTIFIER, @ItemsJson NVARCHAR(MAX)
AS 
BEGIN
    SET NOCOUNT ON;

    -- Parse JSON array of checklist items

    INSERT dbo.ChecklistItems
    (  
       TemplateId,
       ItemText,
       ItemDescription,
       [Order],
       Category,
       Required,
       RequiresPhoto,
       RequiresComment,
       PassFailNA,
       VisualAid,
       CreatedDate
    )
    SELECT @TemplateId,
           JSON_VALUE(value, '$.ItemText'),
           JSON_VALUE(value, '$.ItemDescription'),
           JSON_VALUE(value, '$.Order'),
           JSON_VALUE(value, '$.Category'),
           ISNULL(CAST(JSON_VALUE(value, '$.Required') AS BIT), 1),
           ISNULL(CAST(JSON_VALUE(value, '$.RequiresPhoto') AS BIT), 0),
           ISNULL(CAST(JSON_VALUE(value, '$.RequiresComment') AS BIT), 0),
           ISNULL(CAST(JSON_VALUE(value, '$.PassFailNA') AS BIT), 1),
           JSON_VALUE(value, '$.VisualAid'),
           GETUTCDATE()
    FROM OPENJSON(@ItemsJson);

    SELECT @@ROWCOUNT AS ItemsCreated;
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_ChecklistTemplate_Create]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_ChecklistTemplate_Create]
      @TenantId UNIQUEIDENTIFIER,
      @TemplateName NVARCHAR(200),
      @InspectionType NVARCHAR(50),
      @Standard NVARCHAR(50),
      @Description NVARCHAR(1000) = NULL,
      @TemplateId UNIQUEIDENTIFIER OUTPUT
AS 
BEGIN
    SET NOCOUNT ON;

    SET @TemplateId = NEWID();

    INSERT dbo.ChecklistTemplates
    (  
       TemplateId,
       TenantId,
       TemplateName,
       InspectionType,
       Standard,
       IsSystemTemplate,
       IsActive,
       Description,
       CreatedDate
    )
    VALUES (  
              @TemplateId,
              @TenantId,
              @TemplateName,
              @InspectionType,
              @Standard,
              0,
              1,
              @Description,
              GETUTCDATE()
           );

    SELECT TemplateId,
           TenantId,
           TemplateName,
           InspectionType,
           Standard,
           IsSystemTemplate,
           IsActive,
           Description,
           CreatedDate,
           ModifiedDate
    FROM dbo.ChecklistTemplates
    WHERE TemplateId=@TemplateId;
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_ChecklistTemplate_GetAll]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_ChecklistTemplate_GetAll]
      @TenantId UNIQUEIDENTIFIER = NULL, @IsActive BIT = 1
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT TemplateId,
           TenantId,
           TemplateName,
           InspectionType,
           Standard,
           IsSystemTemplate,
           IsActive,
           Description,
           CreatedDate,
           ModifiedDate
    FROM dbo.ChecklistTemplates
    WHERE (@TenantId IS NULL
            OR TenantId=@TenantId
            OR TenantId IS NULL) -- System templates + tenant templates

          AND (@IsActive IS NULL OR IsActive=@IsActive)
    ORDER BY InspectionType, TemplateName;
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_ChecklistTemplate_GetById]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_ChecklistTemplate_GetById]
      @TemplateId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    -- Get template

    SELECT TemplateId,
           TenantId,
           TemplateName,
           InspectionType,
           Standard,
           IsSystemTemplate,
           IsActive,
           Description,
           CreatedDate,
           ModifiedDate
    FROM dbo.ChecklistTemplates
    WHERE TemplateId=@TemplateId;

    -- Get items
    SELECT ChecklistItemId,
           TemplateId,
           ItemText,
           ItemDescription,
           [Order],
           Category,
           Required,
           RequiresPhoto,
           RequiresComment,
           PassFailNA,
           VisualAid,
           CreatedDate
    FROM dbo.ChecklistItems
    WHERE TemplateId=@TemplateId
    ORDER BY [Order];
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_ChecklistTemplate_GetByType]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_ChecklistTemplate_GetByType]
      @InspectionType NVARCHAR(50), @Standard NVARCHAR(50) = 'NFPA10'
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
           TemplateId,
           TenantId,
           TemplateName,
           InspectionType,
           Standard,
           IsSystemTemplate,
           IsActive,
           Description,
           CreatedDate,
           ModifiedDate
    FROM dbo.ChecklistTemplates
    WHERE InspectionType=@InspectionType
          AND Standard=@Standard
          AND IsActive=1
          AND IsSystemTemplate=1 -- Prefer system templates

    ORDER BY IsSystemTemplate DESC, CreatedDate DESC;
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_Extinguisher_Create]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[usp_Extinguisher_Create]
    @ExtinguisherId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER,
    @LocationId UNIQUEIDENTIFIER,
    @ExtinguisherTypeId UNIQUEIDENTIFIER,
    @AssetTag NVARCHAR(100),
    @BarcodeData NVARCHAR(500) = NULL,
    @Manufacturer NVARCHAR(200) = NULL,
    @Model NVARCHAR(200) = NULL,
    @SerialNumber NVARCHAR(200) = NULL,
    @ManufactureDate DATE = NULL,
    @InstallDate DATE = NULL,
    @LastHydrostaticTestDate DATE = NULL,
    @Capacity NVARCHAR(50) = NULL,
    @LocationDescription NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Extinguishers (
        ExtinguisherId, TenantId, LocationId, ExtinguisherTypeId,
        AssetTag, BarcodeData, Manufacturer, Model, SerialNumber,
        ManufactureDate, InstallDate, LastHydrostaticTestDate,
        Capacity, LocationDescription, IsActive, CreatedDate, ModifiedDate
    )
    VALUES (
        @ExtinguisherId, @TenantId, @LocationId, @ExtinguisherTypeId,
        @AssetTag, @BarcodeData, @Manufacturer, @Model, @SerialNumber,
        @ManufactureDate, @InstallDate, @LastHydrostaticTestDate,
        @Capacity, @LocationDescription, 1, GETUTCDATE(), GETUTCDATE()
    );

    -- Return with joins
    SELECT e.ExtinguisherId, e.TenantId, e.LocationId, e.ExtinguisherTypeId,
           e.AssetTag, e.BarcodeData, e.Manufacturer, e.Model, e.SerialNumber,
           e.ManufactureDate, e.InstallDate, e.LastHydrostaticTestDate,
           e.Capacity, e.LocationDescription, e.IsActive, e.CreatedDate, e.ModifiedDate,
           l.LocationName,
           et.TypeName,
           et.TypeCode
    FROM dbo.Extinguishers e
    LEFT JOIN dbo.Locations l ON e.LocationId = l.LocationId
    LEFT JOIN dbo.ExtinguisherTypes et ON e.ExtinguisherTypeId = et.ExtinguisherTypeId
    WHERE e.ExtinguisherId = @ExtinguisherId;
END;

GO
/****** Object:  StoredProcedure [dbo].[usp_Extinguisher_Delete]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Extinguisher_Delete]
      @ExtinguisherId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.Extinguishers SET IsActive = 0, ModifiedDate = GETUTCDATE()
        WHERE ExtinguisherId=@ExtinguisherId;

        COMMIT TRANSACTION;

        SELECT 'SUCCESS' AS Status;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0
            ROLLBACK TRANSACTION THROW;
    END CATCH;
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_Extinguisher_GetAll]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Extinguisher_GetAll]
      @TenantId UNIQUEIDENTIFIER, @LocationId UNIQUEIDENTIFIER = NULL, @IsActive BIT = NULL
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT e.ExtinguisherId,
           e.TenantId,
           e.LocationId,
           e.ExtinguisherTypeId,
           e.AssetTag,
           e.BarcodeData,
           e.Manufacturer,
           e.Model,
           e.SerialNumber,
           e.ManufactureDate,
           e.InstallDate,
           e.LastHydrostaticTestDate,
           e.Capacity,
           e.LocationDescription,
           e.IsActive,
           e.CreatedDate,
           e.ModifiedDate,
           l.LocationName,
           l.LocationCode,
           et.TypeName,
           et.TypeCode
    FROM dbo.Extinguishers e
    INNER JOIN dbo.Locations l
              ON e.LocationId=l.LocationId
    INNER JOIN dbo.ExtinguisherTypes et
              ON e.ExtinguisherTypeId=et.ExtinguisherTypeId
    WHERE e.TenantId=@TenantId
          AND (@LocationId IS NULL OR e.LocationId=@LocationId)
          AND (@IsActive IS NULL OR e.IsActive=@IsActive)
    ORDER BY l.LocationName, e.AssetTag;
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_Extinguisher_GetByBarcode]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[usp_Extinguisher_GetByBarcode]
    @TenantId UNIQUEIDENTIFIER,
    @BarcodeData NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT e.ExtinguisherId, e.TenantId, e.LocationId, e.ExtinguisherTypeId,
           e.AssetTag, e.BarcodeData, e.Manufacturer, e.Model, e.SerialNumber,
           e.ManufactureDate, e.InstallDate, e.LastHydrostaticTestDate,
           e.Capacity, e.LocationDescription, e.IsActive, e.CreatedDate, e.ModifiedDate,
           l.LocationName,
           et.TypeName,
           et.TypeCode
    FROM dbo.Extinguishers e
    LEFT JOIN dbo.Locations l ON e.LocationId = l.LocationId
    LEFT JOIN dbo.ExtinguisherTypes et ON e.ExtinguisherTypeId = et.ExtinguisherTypeId
    WHERE e.TenantId = @TenantId
      AND e.BarcodeData = @BarcodeData
      AND e.IsActive = 1;
END;
GO
/****** Object:  StoredProcedure [dbo].[usp_Extinguisher_GetById]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Extinguisher_GetById]
      @ExtinguisherId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT e.ExtinguisherId,
           e.TenantId,
           e.LocationId,
           e.ExtinguisherTypeId,
           e.AssetTag,
           e.BarcodeData,
           e.Manufacturer,
           e.Model,
           e.SerialNumber,
           e.ManufactureDate,
           e.InstallDate,
           e.LastHydrostaticTestDate,
           e.Capacity,
           e.LocationDescription,
           e.IsActive,
           e.CreatedDate,
           e.ModifiedDate,
           l.LocationName,
           l.LocationCode,
           et.TypeName,
           et.TypeCode
    FROM dbo.Extinguishers e
    INNER JOIN dbo.Locations l
              ON e.LocationId=l.LocationId
    INNER JOIN dbo.ExtinguisherTypes et
              ON e.ExtinguisherTypeId=et.ExtinguisherTypeId
    WHERE e.ExtinguisherId=@ExtinguisherId;
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_Extinguisher_GetNeedingHydroTest]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[usp_Extinguisher_GetNeedingHydroTest]
    @TenantId UNIQUEIDENTIFIER,
    @MonthsAhead INT = 3
AS
BEGIN
    SET NOCOUNT ON;

    SELECT e.ExtinguisherId, e.TenantId, e.LocationId, e.ExtinguisherTypeId,
           e.AssetTag, e.BarcodeData, e.Manufacturer, e.Model, e.SerialNumber,
           e.ManufactureDate, e.InstallDate, e.LastHydrostaticTestDate,
           e.Capacity, e.LocationDescription, e.IsActive, e.CreatedDate, e.ModifiedDate,
           l.LocationName,
           et.TypeName,
           et.TypeCode,
           et.HydrostaticTestYears,
           DATEADD(YEAR, et.HydrostaticTestYears, ISNULL(e.LastHydrostaticTestDate, e.ManufactureDate)) AS NextHydroTestDue
    FROM dbo.Extinguishers e
    LEFT JOIN dbo.Locations l ON e.LocationId = l.LocationId
    LEFT JOIN dbo.ExtinguisherTypes et ON e.ExtinguisherTypeId = et.ExtinguisherTypeId
    WHERE e.TenantId = @TenantId
      AND e.IsActive = 1
      AND et.HydrostaticTestYears IS NOT NULL
      AND DATEADD(YEAR, et.HydrostaticTestYears, ISNULL(e.LastHydrostaticTestDate, e.ManufactureDate)) <= DATEADD(MONTH, @MonthsAhead, GETUTCDATE())
    ORDER BY DATEADD(YEAR, et.HydrostaticTestYears, ISNULL(e.LastHydrostaticTestDate, e.ManufactureDate));
END;
GO
/****** Object:  StoredProcedure [dbo].[usp_Extinguisher_GetNeedingService]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Extinguisher_GetNeedingService]
      @TenantId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT e.ExtinguisherId,
           e.AssetTag,
           e.LocationDescription,
           l.LocationName,
           et.TypeName
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers e
    INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations l
              ON e.LocationId=l.LocationId
    INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ExtinguisherTypes et
              ON e.ExtinguisherTypeId=et.ExtinguisherTypeId
    WHERE e.TenantId=@TenantId AND e.IsActive=0;
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_Extinguisher_MarkOutOfService]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[usp_Extinguisher_MarkOutOfService]
    @TenantId UNIQUEIDENTIFIER,
    @ExtinguisherId UNIQUEIDENTIFIER,
    @Reason NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Extinguishers
    SET IsActive = 0,
        ModifiedDate = GETUTCDATE()
    WHERE TenantId = @TenantId
      AND ExtinguisherId = @ExtinguisherId;

    -- Return updated record
    SELECT e.ExtinguisherId, e.TenantId, e.LocationId, e.ExtinguisherTypeId,
           e.AssetTag, e.BarcodeData, e.Manufacturer, e.Model, e.SerialNumber,
           e.ManufactureDate, e.InstallDate, e.LastHydrostaticTestDate,
           e.Capacity, e.LocationDescription, e.IsActive, e.CreatedDate, e.ModifiedDate,
           l.LocationName,
           et.TypeName,
           et.TypeCode
    FROM dbo.Extinguishers e
    LEFT JOIN dbo.Locations l ON e.LocationId = l.LocationId
    LEFT JOIN dbo.ExtinguisherTypes et ON e.ExtinguisherTypeId = et.ExtinguisherTypeId
    WHERE e.ExtinguisherId = @ExtinguisherId;
END;
GO
/****** Object:  StoredProcedure [dbo].[usp_Extinguisher_ReturnToService]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[usp_Extinguisher_ReturnToService]
    @TenantId UNIQUEIDENTIFIER,
    @ExtinguisherId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Extinguishers
    SET IsActive = 1,
        ModifiedDate = GETUTCDATE()
    WHERE TenantId = @TenantId
      AND ExtinguisherId = @ExtinguisherId;

    -- Return updated record
    SELECT e.ExtinguisherId, e.TenantId, e.LocationId, e.ExtinguisherTypeId,
           e.AssetTag, e.BarcodeData, e.Manufacturer, e.Model, e.SerialNumber,
           e.ManufactureDate, e.InstallDate, e.LastHydrostaticTestDate,
           e.Capacity, e.LocationDescription, e.IsActive, e.CreatedDate, e.ModifiedDate,
           l.LocationName,
           et.TypeName,
           et.TypeCode
    FROM dbo.Extinguishers e
    LEFT JOIN dbo.Locations l ON e.LocationId = l.LocationId
    LEFT JOIN dbo.ExtinguisherTypes et ON e.ExtinguisherTypeId = et.ExtinguisherTypeId
    WHERE e.ExtinguisherId = @ExtinguisherId;
END;
GO
/****** Object:  StoredProcedure [dbo].[usp_Extinguisher_Update]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[usp_Extinguisher_Update]
    @TenantId UNIQUEIDENTIFIER,
    @ExtinguisherId UNIQUEIDENTIFIER,
    @LocationId UNIQUEIDENTIFIER,
    @ExtinguisherTypeId UNIQUEIDENTIFIER,
    @AssetTag NVARCHAR(100),
    @BarcodeData NVARCHAR(500) = NULL,
    @Manufacturer NVARCHAR(200) = NULL,
    @Model NVARCHAR(200) = NULL,
    @SerialNumber NVARCHAR(200) = NULL,
    @ManufactureDate DATE = NULL,
    @InstallDate DATE = NULL,
    @LastHydrostaticTestDate DATE = NULL,
    @Capacity NVARCHAR(50) = NULL,
    @LocationDescription NVARCHAR(500) = NULL,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Extinguishers
    SET LocationId = @LocationId,
        ExtinguisherTypeId = @ExtinguisherTypeId,
        AssetTag = @AssetTag,
        BarcodeData = @BarcodeData,
        Manufacturer = @Manufacturer,
        Model = @Model,
        SerialNumber = @SerialNumber,
        ManufactureDate = @ManufactureDate,
        InstallDate = @InstallDate,
        LastHydrostaticTestDate = @LastHydrostaticTestDate,
        Capacity = @Capacity,
        LocationDescription = @LocationDescription,
        IsActive = @IsActive,
        ModifiedDate = GETUTCDATE()
    WHERE TenantId = @TenantId
      AND ExtinguisherId = @ExtinguisherId;

    -- Return with joins
    SELECT e.ExtinguisherId, e.TenantId, e.LocationId, e.ExtinguisherTypeId,
           e.AssetTag, e.BarcodeData, e.Manufacturer, e.Model, e.SerialNumber,
           e.ManufactureDate, e.InstallDate, e.LastHydrostaticTestDate,
           e.Capacity, e.LocationDescription, e.IsActive, e.CreatedDate, e.ModifiedDate,
           l.LocationName,
           et.TypeName,
           et.TypeCode
    FROM dbo.Extinguishers e
    LEFT JOIN dbo.Locations l ON e.LocationId = l.LocationId
    LEFT JOIN dbo.ExtinguisherTypes et ON e.ExtinguisherTypeId = et.ExtinguisherTypeId
    WHERE e.ExtinguisherId = @ExtinguisherId;
END;

GO
/****** Object:  StoredProcedure [dbo].[usp_ExtinguisherType_Create]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[usp_ExtinguisherType_Create]
    @ExtinguisherTypeId UNIQUEIDENTIFIER,
    @TypeCode NVARCHAR(50),
    @TypeName NVARCHAR(200),
    @Description NVARCHAR(MAX) = NULL,
    @MonthlyInspectionRequired BIT = 1,
    @AnnualInspectionRequired BIT = 1,
    @HydrostaticTestYears INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.ExtinguisherTypes (
        ExtinguisherTypeId, TypeCode, TypeName, Description,
        MonthlyInspectionRequired, AnnualInspectionRequired,
        HydrostaticTestYears, IsActive, CreatedDate
    )
    VALUES (
        @ExtinguisherTypeId, @TypeCode, @TypeName, @Description,
        @MonthlyInspectionRequired, @AnnualInspectionRequired,
        @HydrostaticTestYears, 1, GETUTCDATE()
    );

    SELECT ExtinguisherTypeId, TypeCode, TypeName, Description,
           MonthlyInspectionRequired, AnnualInspectionRequired,
           HydrostaticTestYears, IsActive, CreatedDate
    FROM dbo.ExtinguisherTypes
    WHERE ExtinguisherTypeId = @ExtinguisherTypeId;
END;

GO
/****** Object:  StoredProcedure [dbo].[usp_ExtinguisherType_GetAll]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- Create in dbo schema
CREATE   PROCEDURE [dbo].[usp_ExtinguisherType_GetAll]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ExtinguisherTypeId, TypeCode, TypeName, Description,
           MonthlyInspectionRequired, AnnualInspectionRequired,
           HydrostaticTestYears, IsActive, CreatedDate
    FROM dbo.ExtinguisherTypes
    WHERE IsActive = 1
    ORDER BY TypeName;
END;

GO
/****** Object:  StoredProcedure [dbo].[usp_ExtinguisherType_GetById]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[usp_ExtinguisherType_GetById]
    @ExtinguisherTypeId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ExtinguisherTypeId, TypeCode, TypeName, Description,
           MonthlyInspectionRequired, AnnualInspectionRequired,
           HydrostaticTestYears, IsActive, CreatedDate
    FROM dbo.ExtinguisherTypes
    WHERE ExtinguisherTypeId = @ExtinguisherTypeId;
END;

GO
/****** Object:  StoredProcedure [dbo].[usp_ExtinguisherType_Update]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[usp_ExtinguisherType_Update]
    @ExtinguisherTypeId UNIQUEIDENTIFIER,
    @TypeCode NVARCHAR(50),
    @TypeName NVARCHAR(200),
    @Description NVARCHAR(MAX) = NULL,
    @MonthlyInspectionRequired BIT = 1,
    @AnnualInspectionRequired BIT = 1,
    @HydrostaticTestYears INT = NULL,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.ExtinguisherTypes
    SET TypeCode = @TypeCode,
        TypeName = @TypeName,
        Description = @Description,
        MonthlyInspectionRequired = @MonthlyInspectionRequired,
        AnnualInspectionRequired = @AnnualInspectionRequired,
        HydrostaticTestYears = @HydrostaticTestYears,
        IsActive = @IsActive
    WHERE ExtinguisherTypeId = @ExtinguisherTypeId;

    SELECT ExtinguisherTypeId, TypeCode, TypeName, Description,
           MonthlyInspectionRequired, AnnualInspectionRequired,
           HydrostaticTestYears, IsActive, CreatedDate
    FROM dbo.ExtinguisherTypes
    WHERE ExtinguisherTypeId = @ExtinguisherTypeId;
END;

GO
/****** Object:  StoredProcedure [dbo].[usp_Inspection_Delete]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[usp_Inspection_Delete]
    @TenantId UNIQUEIDENTIFIER,
    @InspectionId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Hard delete (inspections are immutable by design, but allow admin deletion)
    DELETE FROM dbo.Inspections
    WHERE TenantId = @TenantId
      AND InspectionId = @InspectionId;

    SELECT @@ROWCOUNT AS RowsAffected;
END;
GO
/****** Object:  StoredProcedure [dbo].[usp_Inspection_GetAll]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[usp_Inspection_GetAll]
    @TenantId UNIQUEIDENTIFIER,
    @ExtinguisherId UNIQUEIDENTIFIER = NULL,
    @InspectorUserId UNIQUEIDENTIFIER = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @InspectionType NVARCHAR(50) = NULL,
    @Passed BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        i.InspectionId,
        i.TenantId,
        i.ExtinguisherId,
        i.InspectorUserId,
        i.InspectionDate,
        i.InspectionType,              -- Now using actual column
        i.GpsLatitude,                 -- Renamed column
        i.GpsLongitude,                -- Renamed column
        i.GpsAccuracyMeters,           -- Now using actual column
        i.LocationVerified,            -- Now using actual column
        i.IsAccessible,
        i.HasObstructions,
        i.SignageVisible,
        i.SealIntact,
        i.PinInPlace,
        i.NozzleClear,
        i.HoseConditionGood,
        i.GaugeInGreenZone,
        i.GaugePressurePsi,
        i.PhysicalDamagePresent,
        i.DamageDescription,           -- Now using actual column
        i.WeightPounds,                -- Now using actual column
        i.WeightWithinSpec,            -- Now using actual column
        i.InspectionTagAttached,
        i.PreviousInspectionDate,      -- Now using actual column
        i.Notes,
        i.Passed,
        i.RequiresService,
        i.RequiresReplacement,
        i.FailureReason,
        i.CorrectiveAction,
        i.PhotoUrls,                   -- Now using actual column
        i.DataHash,                    -- Now using actual column
        i.InspectorSignature,          -- Now using actual column
        i.SignedDate,                  -- Now using actual column
        i.IsVerified,                  -- Now using actual column
        i.CreatedDate,
        i.ModifiedDate,                -- Now using actual column
        e.AssetTag AS ExtinguisherCode,
        u.Email AS InspectorName,
        l.LocationName
    FROM dbo.Inspections i
    LEFT JOIN dbo.Extinguishers e ON i.ExtinguisherId = e.ExtinguisherId
    LEFT JOIN dbo.Users u ON i.InspectorUserId = u.UserId
    LEFT JOIN dbo.Locations l ON e.LocationId = l.LocationId
    WHERE i.TenantId = @TenantId
      AND (@ExtinguisherId IS NULL OR i.ExtinguisherId = @ExtinguisherId)
      AND (@InspectorUserId IS NULL OR i.InspectorUserId = @InspectorUserId)
      AND (@StartDate IS NULL OR i.InspectionDate >= @StartDate)
      AND (@EndDate IS NULL OR i.InspectionDate <= @EndDate)
      AND (@InspectionType IS NULL OR i.InspectionType = @InspectionType)
      AND (@Passed IS NULL OR i.Passed = @Passed)
    ORDER BY i.InspectionDate DESC;
END;

GO
/****** Object:  StoredProcedure [dbo].[usp_Inspection_GetById]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Inspection_GetById]
      @InspectionId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT i.InspectionId,
           i.TenantId,
           i.ExtinguisherId,
           i.InspectionTypeId,
           i.InspectorUserId,
           i.InspectionDate,
           i.InspectionDate, 
           i.GpsLatitude,
           i.GpsLongitude,
           i.GpsAccuracyMeters,
           i.Notes,
           e.AssetTag,
           l.LocationName,
           it.TypeName AS InspectionTypeName
    FROM dbo.Inspections i
    INNER JOIN dbo.Extinguishers e
              ON i.ExtinguisherId=e.ExtinguisherId
    INNER JOIN dbo.Locations l
              ON e.LocationId=l.LocationId
    INNER JOIN dbo.InspectionTypes it
              ON i.InspectionTypeId=it.InspectionTypeId
    WHERE i.InspectionId=@InspectionId;
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_Inspection_GetOverdue]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[usp_Inspection_GetOverdue]
    @TenantId UNIQUEIDENTIFIER,
    @DaysOverdue INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    -- Get extinguishers without recent inspections based on inspection type frequency
    WITH LatestInspections AS (
        SELECT
            ExtinguisherId,
            MAX(InspectionDate) AS LastInspectionDate
        FROM dbo.Inspections
        WHERE TenantId = @TenantId
        GROUP BY ExtinguisherId
    )
    SELECT e.ExtinguisherId, e.TenantId, e.LocationId, e.ExtinguisherTypeId,
           e.AssetTag, e.BarcodeData, e.Manufacturer, e.Model, e.SerialNumber,
           l.LocationName,
           et.TypeName,
           li.LastInspectionDate,
           DATEDIFF(DAY, li.LastInspectionDate, GETUTCDATE()) AS DaysSinceInspection
    FROM dbo.Extinguishers e
    LEFT JOIN dbo.Locations l ON e.LocationId = l.LocationId
    LEFT JOIN dbo.ExtinguisherTypes et ON e.ExtinguisherTypeId = et.ExtinguisherTypeId
    LEFT JOIN LatestInspections li ON e.ExtinguisherId = li.ExtinguisherId
    WHERE e.TenantId = @TenantId
      AND e.IsActive = 1
      AND (li.LastInspectionDate IS NULL
           OR DATEDIFF(DAY, li.LastInspectionDate, GETUTCDATE()) > @DaysOverdue)
    ORDER BY li.LastInspectionDate ASC;
END;
GO
/****** Object:  StoredProcedure [dbo].[usp_Inspection_GetStats]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[usp_Inspection_GetStats]
    @TenantId UNIQUEIDENTIFIER,
    @StartDate DATETIME2 = NULL,
    @EndDate DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Default to last 30 days if no date range specified
    IF @StartDate IS NULL
        SET @StartDate = DATEADD(DAY, -30, GETUTCDATE());

    IF @EndDate IS NULL
        SET @EndDate = GETUTCDATE();

    SELECT
        COUNT(*) AS TotalInspections,
        SUM(CASE WHEN Passed = 1 THEN 1 ELSE 0 END) AS PassedInspections,
        SUM(CASE WHEN Passed = 0 THEN 1 ELSE 0 END) AS FailedInspections,
        CASE
            WHEN COUNT(*) > 0
            THEN CAST(SUM(CASE WHEN Passed = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100
            ELSE 0
        END AS PassRate,
        SUM(CASE WHEN RequiresService = 1 THEN 1 ELSE 0 END) AS RequiringService,
        SUM(CASE WHEN RequiresReplacement = 1 THEN 1 ELSE 0 END) AS RequiringReplacement,
        MAX(InspectionDate) AS LastInspectionDate,
        SUM(CASE
            WHEN YEAR(InspectionDate) = YEAR(GETUTCDATE())
             AND MONTH(InspectionDate) = MONTH(GETUTCDATE())
            THEN 1
            ELSE 0
        END) AS InspectionsThisMonth,
        SUM(CASE
            WHEN YEAR(InspectionDate) = YEAR(GETUTCDATE())
            THEN 1
            ELSE 0
        END) AS InspectionsThisYear
    FROM dbo.Inspections
    WHERE TenantId = @TenantId
      AND InspectionDate >= @StartDate
      AND InspectionDate <= @EndDate;
END;

GO
/****** Object:  StoredProcedure [dbo].[usp_InspectionChecklistResponse_CreateBatch]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_InspectionChecklistResponse_CreateBatch]
      @InspectionId UNIQUEIDENTIFIER, @ResponsesJson NVARCHAR(MAX)
AS 
BEGIN
    SET NOCOUNT ON;

    -- Parse JSON array of responses

    INSERT dbo.InspectionChecklistResponses
    (  
       InspectionId,
       ChecklistItemId,
       Response,
       Comment,
       PhotoId,
       CreatedDate
    )
    SELECT @InspectionId,
           CAST(JSON_VALUE(value, '$.ChecklistItemId') AS UNIQUEIDENTIFIER),
           JSON_VALUE(value, '$.Response'),
           JSON_VALUE(value, '$.Comment'),
           CAST(JSON_VALUE(value, '$.PhotoId') AS UNIQUEIDENTIFIER),
           GETUTCDATE()
    FROM OPENJSON(@ResponsesJson);

    SELECT @@ROWCOUNT AS ResponsesCreated;
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_InspectionChecklistResponse_GetByInspection]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_InspectionChecklistResponse_GetByInspection]
      @InspectionId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT r.ResponseId,
           r.InspectionId,
           r.ChecklistItemId,
           r.Response,
           r.Comment,
           r.PhotoId,
           r.CreatedDate,
           i.ItemText,
           i.Category,
           i.[Order]
    FROM dbo.InspectionChecklistResponses r
    LEFT JOIN dbo.ChecklistItems i
              ON r.ChecklistItemId=i.ChecklistItemId
    WHERE r.InspectionId=@InspectionId
    ORDER BY i.[Order];
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_InspectionDeficiency_Create]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_InspectionDeficiency_Create]
      @InspectionId UNIQUEIDENTIFIER,
      @DeficiencyType NVARCHAR(50),
      @Severity NVARCHAR(20),
      @Description NVARCHAR(1000),
      @ActionRequired NVARCHAR(500) = NULL,
      @EstimatedCost DECIMAL(10, 2) = NULL,
      @AssignedToUserId UNIQUEIDENTIFIER = NULL,
      @DueDate DATE = NULL,
      @PhotoIds NVARCHAR(MAX) = NULL,
      @DeficiencyId UNIQUEIDENTIFIER OUTPUT
AS 
BEGIN
    SET NOCOUNT ON;

    SET @DeficiencyId = NEWID();

    INSERT dbo.InspectionDeficiencies
    (  
       DeficiencyId,
       InspectionId,
       DeficiencyType,
       Severity,
       Description,
       Status,
       ActionRequired,
       EstimatedCost,
       AssignedToUserId,
       DueDate,
       PhotoIds,
       CreatedDate
    )
    VALUES (  
              @DeficiencyId,
              @InspectionId,
              @DeficiencyType,
              @Severity,
              @Description,
              'Open',
              @ActionRequired,
              @EstimatedCost,
              @AssignedToUserId,
              @DueDate,
              @PhotoIds,
              GETUTCDATE()
           );

    SELECT DeficiencyId,
           InspectionId,
           DeficiencyType,
           Severity,
           Description,
           Status,
           ActionRequired,
           EstimatedCost,
           AssignedToUserId,
           DueDate,
           CreatedDate
    FROM dbo.InspectionDeficiencies
    WHERE DeficiencyId=@DeficiencyId;
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_InspectionDeficiency_GetByInspection]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_InspectionDeficiency_GetByInspection]
      @InspectionId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT DeficiencyId,
           InspectionId,
           DeficiencyType,
           Severity,
           Description,
           Status,
           ActionRequired,
           EstimatedCost,
           AssignedToUserId,
           DueDate,
           ResolutionNotes,
           ResolvedDate,
           ResolvedByUserId,
           PhotoIds,
           CreatedDate,
           ModifiedDate
    FROM dbo.InspectionDeficiencies
    WHERE InspectionId=@InspectionId
    ORDER BY Severity DESC, CreatedDate DESC;
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_InspectionDeficiency_GetBySeverity]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_InspectionDeficiency_GetBySeverity]
      @TenantId UNIQUEIDENTIFIER, @Severity NVARCHAR(20)
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT d.DeficiencyId,
           d.InspectionId,
           d.DeficiencyType,
           d.Severity,
           d.Description,
           d.Status,
           d.ActionRequired,
           d.EstimatedCost,
           d.AssignedToUserId,
           d.DueDate,
           d.CreatedDate,
           i.ExtinguisherId,
           e.AssetTag,
           e.BarcodeData,
           l.LocationName
    FROM dbo.InspectionDeficiencies d
    INNER JOIN dbo.Inspections i
              ON d.InspectionId=i.InspectionId
    INNER JOIN dbo.Extinguishers e
              ON i.ExtinguisherId=e.ExtinguisherId
    LEFT JOIN dbo.Locations l
              ON e.LocationId=l.LocationId
    WHERE i.TenantId=@TenantId
          AND d.Severity=@Severity
          AND d.Status IN('Open', 'InProgress')
    ORDER BY d.CreatedDate DESC;
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_InspectionDeficiency_GetOpen]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_InspectionDeficiency_GetOpen]
      @TenantId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT d.DeficiencyId,
           d.InspectionId,
           d.DeficiencyType,
           d.Severity,
           d.Description,
           d.Status,
           d.ActionRequired,
           d.EstimatedCost,
           d.AssignedToUserId,
           d.DueDate,
           d.CreatedDate,
           i.ExtinguisherId,
           e.AssetTag,
           e.BarcodeData,
           l.LocationName
    FROM dbo.InspectionDeficiencies d
    INNER JOIN dbo.Inspections i
              ON d.InspectionId=i.InspectionId
    INNER JOIN dbo.Extinguishers e
              ON i.ExtinguisherId=e.ExtinguisherId
    LEFT JOIN dbo.Locations l
              ON e.LocationId=l.LocationId
    WHERE i.TenantId=@TenantId AND d.Status IN('Open', 'InProgress')
    ORDER BY d.Severity DESC, d.CreatedDate DESC;
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_InspectionDeficiency_Resolve]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_InspectionDeficiency_Resolve]
      @DeficiencyId UNIQUEIDENTIFIER, @ResolvedByUserId UNIQUEIDENTIFIER, @ResolutionNotes NVARCHAR(1000)
AS 
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.InspectionDeficiencies SET Status = 'Resolved',
                                                                                    ResolvedByUserId = @ResolvedByUserId,
                                                                                    ResolvedDate = GETUTCDATE(),
                                                                                    ResolutionNotes = @ResolutionNotes,
                                                                                    ModifiedDate = GETUTCDATE()
    WHERE DeficiencyId=@DeficiencyId;

    SELECT DeficiencyId,
           Status,
           ResolvedByUserId,
           ResolvedDate,
           ResolutionNotes
    FROM dbo.InspectionDeficiencies
    WHERE DeficiencyId=@DeficiencyId;
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_InspectionDeficiency_Update]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_InspectionDeficiency_Update]
      @DeficiencyId UNIQUEIDENTIFIER,
      @Status NVARCHAR(20) = NULL,
      @ActionRequired NVARCHAR(500) = NULL,
      @EstimatedCost DECIMAL(10, 2) = NULL,
      @AssignedToUserId UNIQUEIDENTIFIER = NULL,
      @DueDate DATE = NULL
AS 
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.InspectionDeficiencies SET Status = ISNULL(@Status, Status),
                                                                                    ActionRequired = ISNULL(@ActionRequired, ActionRequired),
                                                                                    EstimatedCost = ISNULL(@EstimatedCost, EstimatedCost),
                                                                                    AssignedToUserId = ISNULL(@AssignedToUserId, AssignedToUserId),
                                                                                    DueDate = ISNULL(@DueDate, DueDate),
                                                                                    ModifiedDate = GETUTCDATE()
    WHERE DeficiencyId=@DeficiencyId;
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_InspectionPhoto_Create]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_InspectionPhoto_Create]
      @InspectionId UNIQUEIDENTIFIER,
      @PhotoType NVARCHAR(50),
      @BlobUrl NVARCHAR(500),
      @ThumbnailUrl NVARCHAR(500) = NULL,
      @FileSize BIGINT = NULL,
      @MimeType NVARCHAR(100) = NULL,
      @CaptureDate DATETIME2 = NULL,
      @Latitude DECIMAL(9, 6) = NULL,
      @Longitude DECIMAL(9, 6) = NULL,
      @DeviceModel NVARCHAR(200) = NULL,
      @EXIFData NVARCHAR(MAX) = NULL,
      @Notes NVARCHAR(500) = NULL,
      @PhotoId UNIQUEIDENTIFIER OUTPUT
AS 
BEGIN
    SET NOCOUNT ON;

    SET @PhotoId = NEWID();

    INSERT dbo.InspectionPhotos
    (  
       PhotoId,
       InspectionId,
       PhotoType,
       BlobUrl,
       ThumbnailUrl,
       FileSize,
       MimeType,
       CaptureDate,
       Latitude,
       Longitude,
       DeviceModel,
       EXIFData,
       Notes,
       CreatedDate
    )
    VALUES (  
              @PhotoId,
              @InspectionId,
              @PhotoType,
              @BlobUrl,
              @ThumbnailUrl,
              @FileSize,
              @MimeType,
              @CaptureDate,
              @Latitude,
              @Longitude,
              @DeviceModel,
              @EXIFData,
              @Notes,
              GETUTCDATE()
           );

    SELECT PhotoId,
           InspectionId,
           PhotoType,
           BlobUrl,
           ThumbnailUrl,
           FileSize,
           MimeType,
           CaptureDate,
           Latitude,
           Longitude,
           CreatedDate
    FROM dbo.InspectionPhotos
    WHERE PhotoId=@PhotoId;
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_InspectionPhoto_GetByInspection]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_InspectionPhoto_GetByInspection]
      @InspectionId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT PhotoId,
           InspectionId,
           PhotoType,
           BlobUrl,
           ThumbnailUrl,
           FileSize,
           MimeType,
           CaptureDate,
           Latitude,
           Longitude,
           DeviceModel,
           Notes,
           CreatedDate
    FROM dbo.InspectionPhotos
    WHERE InspectionId=@InspectionId
    ORDER BY CreatedDate ASC;
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_InspectionPhoto_GetByType]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_InspectionPhoto_GetByType]
      @InspectionId UNIQUEIDENTIFIER, @PhotoType NVARCHAR(50)
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT PhotoId,
           InspectionId,
           PhotoType,
           BlobUrl,
           ThumbnailUrl,
           FileSize,
           MimeType,
           CaptureDate,
           Latitude,
           Longitude,
           Notes,
           CreatedDate
    FROM dbo.InspectionPhotos
    WHERE InspectionId=@InspectionId AND PhotoType=@PhotoType
    ORDER BY CreatedDate ASC;
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_InspectionType_Create]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[usp_InspectionType_Create]
    @InspectionTypeId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER,
    @TypeName NVARCHAR(200),
    @Description NVARCHAR(MAX) = NULL,
    @RequiresServiceTechnician BIT = 0,
    @FrequencyDays INT = 365
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.InspectionTypes (
        InspectionTypeId, TenantId, TypeName, Description,
        RequiresServiceTechnician, FrequencyDays, IsActive, CreatedDate
    )
    VALUES (
        @InspectionTypeId, @TenantId, @TypeName, @Description,
        @RequiresServiceTechnician, @FrequencyDays, 1, GETUTCDATE()
    );

    SELECT InspectionTypeId, TenantId, TypeName, Description,
           RequiresServiceTechnician, FrequencyDays, IsActive, CreatedDate
    FROM dbo.InspectionTypes
    WHERE InspectionTypeId = @InspectionTypeId;
END;

GO
/****** Object:  StoredProcedure [dbo].[usp_InspectionType_GetAll]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- ============================================================================
-- INSPECTION TYPES (Tenant-Specific - WITH TenantId)
-- ============================================================================

CREATE   PROCEDURE [dbo].[usp_InspectionType_GetAll]
    @TenantId UNIQUEIDENTIFIER = NULL  -- Optional: NULL returns all, specific ID filters by tenant
AS
BEGIN
    SET NOCOUNT ON;

    SELECT InspectionTypeId, TenantId, TypeName, Description,
           RequiresServiceTechnician, FrequencyDays, IsActive, CreatedDate
    FROM dbo.InspectionTypes
    WHERE (@TenantId IS NULL OR TenantId = @TenantId)
      AND IsActive = 1
    ORDER BY TypeName;
END;

GO
/****** Object:  StoredProcedure [dbo].[usp_InspectionType_GetById]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[usp_InspectionType_GetById]
    @InspectionTypeId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT InspectionTypeId, TenantId, TypeName, Description,
           RequiresServiceTechnician, FrequencyDays, IsActive, CreatedDate
    FROM dbo.InspectionTypes
    WHERE InspectionTypeId = @InspectionTypeId
      AND (@TenantId IS NULL OR TenantId = @TenantId);
END;

GO
/****** Object:  StoredProcedure [dbo].[usp_InspectionType_Update]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[usp_InspectionType_Update]
    @InspectionTypeId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER,
    @TypeName NVARCHAR(200),
    @Description NVARCHAR(MAX) = NULL,
    @RequiresServiceTechnician BIT = 0,
    @FrequencyDays INT = 365,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.InspectionTypes
    SET TypeName = @TypeName,
        Description = @Description,
        RequiresServiceTechnician = @RequiresServiceTechnician,
        FrequencyDays = @FrequencyDays,
        IsActive = @IsActive
    WHERE InspectionTypeId = @InspectionTypeId
      AND TenantId = @TenantId;

    SELECT InspectionTypeId, TenantId, TypeName, Description,
           RequiresServiceTechnician, FrequencyDays, IsActive, CreatedDate
    FROM dbo.InspectionTypes
    WHERE InspectionTypeId = @InspectionTypeId;
END;

GO
/****** Object:  StoredProcedure [dbo].[usp_Location_Create]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[usp_Location_Create]
    @LocationId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER,
    @LocationCode NVARCHAR(50),
    @LocationName NVARCHAR(200),
    @AddressLine1 NVARCHAR(200) = NULL,
    @AddressLine2 NVARCHAR(200) = NULL,
    @City NVARCHAR(100) = NULL,
    @StateProvince NVARCHAR(100) = NULL,
    @PostalCode NVARCHAR(20) = NULL,
    @Country NVARCHAR(100) = NULL,
    @ContactName NVARCHAR(200) = NULL,
    @ContactPhone NVARCHAR(50) = NULL,
    @ContactEmail NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Locations (
        LocationId, TenantId, LocationCode, LocationName,
        AddressLine1, AddressLine2, City, StateProvince, PostalCode, Country,
        ContactName, ContactPhone, ContactEmail, IsActive, CreatedDate, ModifiedDate
    )
    VALUES (
        @LocationId, @TenantId, @LocationCode, @LocationName,
        @AddressLine1, @AddressLine2, @City, @StateProvince, @PostalCode, @Country,
        @ContactName, @ContactPhone, @ContactEmail, 1, GETUTCDATE(), GETUTCDATE()
    );

    SELECT LocationId, TenantId, LocationCode, LocationName,
           AddressLine1, AddressLine2, City, StateProvince, PostalCode, Country,
           ContactName, ContactPhone, ContactEmail, IsActive, CreatedDate, ModifiedDate
    FROM dbo.Locations
    WHERE LocationId = @LocationId;
END;

GO
/****** Object:  StoredProcedure [dbo].[usp_Location_GetAll]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Location_GetAll]
      @TenantId UNIQUEIDENTIFIER, @IsActive BIT = NULL
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT LocationId,
           TenantId,
           LocationCode,
           LocationName,
           AddressLine1,
           AddressLine2,
           City,
           StateProvince,
           PostalCode,
           Country,
           Latitude,
           Longitude,
           LocationBarcodeData,
           IsActive,
           CreatedDate,
           ModifiedDate
    FROM dbo.Locations
    WHERE TenantId=@TenantId AND (@IsActive IS NULL OR IsActive=@IsActive)
    ORDER BY LocationName;
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_Location_GetById]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Location_GetById]
      @LocationId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT LocationId,
           TenantId,
           LocationCode,
           LocationName,
           AddressLine1,
           AddressLine2,
           City,
           StateProvince,
           PostalCode,
           Country,
           Latitude,
           Longitude,
           LocationBarcodeData,
           IsActive,
           CreatedDate,
           ModifiedDate
    FROM dbo.Locations
    WHERE LocationId=@LocationId;
END;


GO
/****** Object:  StoredProcedure [dbo].[usp_Location_Update]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[usp_Location_Update]
    @TenantId UNIQUEIDENTIFIER,
    @LocationId UNIQUEIDENTIFIER,
    @LocationCode NVARCHAR(50),
    @LocationName NVARCHAR(200),
    @AddressLine1 NVARCHAR(200) = NULL,
    @AddressLine2 NVARCHAR(200) = NULL,
    @City NVARCHAR(100) = NULL,
    @StateProvince NVARCHAR(100) = NULL,
    @PostalCode NVARCHAR(20) = NULL,
    @Country NVARCHAR(100) = NULL,
    @ContactName NVARCHAR(200) = NULL,
    @ContactPhone NVARCHAR(50) = NULL,
    @ContactEmail NVARCHAR(200) = NULL,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Locations
    SET LocationCode = @LocationCode,
        LocationName = @LocationName,
        AddressLine1 = @AddressLine1,
        AddressLine2 = @AddressLine2,
        City = @City,
        StateProvince = @StateProvince,
        PostalCode = @PostalCode,
        Country = @Country,
        ContactName = @ContactName,
        ContactPhone = @ContactPhone,
        ContactEmail = @ContactEmail,
        IsActive = @IsActive,
        ModifiedDate = GETUTCDATE()
    WHERE TenantId = @TenantId
      AND LocationId = @LocationId;

    SELECT LocationId, TenantId, LocationCode, LocationName,
           AddressLine1, AddressLine2, City, StateProvince, PostalCode, Country,
           ContactName, ContactPhone, ContactEmail, IsActive, CreatedDate, ModifiedDate
    FROM dbo.Locations
    WHERE LocationId = @LocationId;
END;

GO
/****** Object:  StoredProcedure [dbo].[usp_Tenant_Create]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Tenant_Create]
    @TenantCode NVARCHAR(50),
    @CompanyName NVARCHAR(200),
    @SubscriptionTier NVARCHAR(50) = 'Free',
    @MaxLocations INT = 10,
    @MaxUsers INT = 5,
    @MaxExtinguishers INT = 100
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @NewTenantId UNIQUEIDENTIFIER = NEWID()
    DECLARE @DatabaseSchema NVARCHAR(128) = 'tenant_' + CAST(@NewTenantId AS NVARCHAR(36))

    -- Validate subscription tier
    IF @SubscriptionTier NOT IN ('Free', 'Standard', 'Premium')
    BEGIN
        RAISERROR('Invalid subscription tier. Must be Free, Standard, or Premium', 16, 1)
        RETURN
    END

    -- Check if tenant code already exists
    IF EXISTS (SELECT 1 FROM dbo.Tenants WHERE TenantCode = @TenantCode)
    BEGIN
        RAISERROR('Tenant code already exists', 16, 1)
        RETURN
    END

    -- Insert new tenant
    INSERT INTO dbo.Tenants (
        TenantId,
        TenantCode,
        CompanyName,
        SubscriptionTier,
        IsActive,
        MaxLocations,
        MaxUsers,
        MaxExtinguishers,
        DatabaseSchema,
        CreatedDate,
        ModifiedDate
    )
    VALUES (
        @NewTenantId,
        @TenantCode,
        @CompanyName,
        @SubscriptionTier,
        1, -- IsActive
        @MaxLocations,
        @MaxUsers,
        @MaxExtinguishers,
        @DatabaseSchema,
        GETUTCDATE(),
        GETUTCDATE()
    )

    -- Return the new tenant
    SELECT
        TenantId,
        TenantCode,
        CompanyName AS TenantName,
        SubscriptionTier,
        IsActive,
        MaxLocations,
        MaxUsers,
        MaxExtinguishers,
        DatabaseSchema,
        CreatedDate,
        ModifiedDate
    FROM dbo.Tenants
    WHERE TenantId = @NewTenantId
END

GO
/****** Object:  StoredProcedure [dbo].[usp_Tenant_GetAll]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[usp_Tenant_GetAll]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TenantId, TenantCode, CompanyName, SubscriptionTier,
           IsActive, MaxLocations, MaxUsers, MaxExtinguishers,
           DatabaseSchema, CreatedDate, ModifiedDate
    FROM dbo.Tenants
    WHERE IsActive = 1
    ORDER BY CompanyName;
END;
GO
/****** Object:  StoredProcedure [dbo].[usp_Tenant_GetAvailableForUser]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[usp_Tenant_GetAvailableForUser]
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Get tenants the user has access to via UserTenantRoles
    SELECT DISTINCT t.TenantId, t.TenantCode, t.CompanyName, t.SubscriptionTier,
           t.IsActive, t.MaxLocations, t.MaxUsers, t.MaxExtinguishers,
           t.DatabaseSchema, t.CreatedDate, t.ModifiedDate,
           utr.RoleName AS UserRole
    FROM dbo.Tenants t
    INNER JOIN dbo.UserTenantRoles utr ON t.TenantId = utr.TenantId
    WHERE utr.UserId = @UserId
      AND t.IsActive = 1
      AND utr.IsActive = 1
    ORDER BY t.CompanyName;
END;
GO
/****** Object:  StoredProcedure [dbo].[usp_Tenant_GetById]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[usp_Tenant_GetById]
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TenantId, TenantCode, CompanyName, SubscriptionTier,
           IsActive, MaxLocations, MaxUsers, MaxExtinguishers,
           DatabaseSchema, CreatedDate, ModifiedDate
    FROM dbo.Tenants
    WHERE TenantId = @TenantId;
END;
GO
/****** Object:  StoredProcedure [dbo].[usp_Tenant_Update]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[usp_Tenant_Update]
    @TenantId UNIQUEIDENTIFIER,
    @TenantCode NVARCHAR(50),
    @CompanyName NVARCHAR(200),
    @SubscriptionTier NVARCHAR(50),
    @MaxLocations INT,
    @MaxUsers INT,
    @MaxExtinguishers INT,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Tenants
    SET TenantCode = @TenantCode,
        CompanyName = @CompanyName,
        SubscriptionTier = @SubscriptionTier,
        MaxLocations = @MaxLocations,
        MaxUsers = @MaxUsers,
        MaxExtinguishers = @MaxExtinguishers,
        IsActive = @IsActive,
        ModifiedDate = GETUTCDATE()
    WHERE TenantId = @TenantId;

    -- Return updated tenant
    SELECT TenantId, TenantCode, CompanyName, SubscriptionTier,
           IsActive, MaxLocations, MaxUsers, MaxExtinguishers,
           DatabaseSchema, CreatedDate, ModifiedDate
    FROM dbo.Tenants
    WHERE TenantId = @TenantId;
END;
GO
/****** Object:  StoredProcedure [dbo].[usp_User_AssignToTenant]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_User_AssignToTenant]
    @UserId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER,
    @RoleName NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON

    -- Check if user exists
    IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UserId = @UserId AND IsActive = 1)
    BEGIN
        RAISERROR('User not found', 16, 1)
        RETURN
    END

    -- Check if tenant exists
    IF NOT EXISTS (SELECT 1 FROM dbo.Tenants WHERE TenantId = @TenantId AND IsActive = 1)
    BEGIN
        RAISERROR('Tenant not found', 16, 1)
        RETURN
    END

    -- Check if assignment already exists
    IF EXISTS (
        SELECT 1 FROM dbo.UserTenantRoles
        WHERE UserId = @UserId AND TenantId = @TenantId AND RoleName = @RoleName AND IsActive = 1
    )
    BEGIN
        RAISERROR('User already assigned to this tenant with this role', 16, 1)
        RETURN
    END

    -- Create assignment
    INSERT INTO dbo.UserTenantRoles (UserId, TenantId, RoleName, IsActive, CreatedDate)
    VALUES (@UserId, @TenantId, @RoleName, 1, GETUTCDATE())

    -- Return the created assignment
    SELECT
        UserTenantRoleId,
        UserId,
        TenantId,
        RoleName,
        IsActive,
        CreatedDate
    FROM dbo.UserTenantRoles
    WHERE UserId = @UserId AND TenantId = @TenantId AND RoleName = @RoleName AND IsActive = 1
END

GO
/****** Object:  StoredProcedure [dbo].[usp_User_ConfirmEmail]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_User_ConfirmEmail]
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON

    UPDATE dbo.Users
    SET
        EmailConfirmed = 1,
        ModifiedDate = GETUTCDATE()
    WHERE UserId = @UserId

    SELECT @@ROWCOUNT AS RowsAffected
END

GO
/****** Object:  StoredProcedure [dbo].[usp_User_Create]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_User_Create]
    @Email NVARCHAR(256),
    @FirstName NVARCHAR(100),
    @LastName NVARCHAR(100),
    @AzureAdB2CObjectId NVARCHAR(128) = NULL,
    @UserId UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        -- Check if user already exists
        IF EXISTS (SELECT 1 FROM dbo.Users WHERE Email = @Email AND IsActive = 1)
        BEGIN
            SELECT @UserId = UserId FROM dbo.Users WHERE Email = @Email AND IsActive = 1
            SELECT @UserId AS UserId, 'USER_EXISTS' AS Status
            RETURN
        END

        SET @UserId = NEWID()

        INSERT INTO dbo.Users (UserId, Email, FirstName, LastName, AzureAdB2CObjectId, IsActive)
        VALUES (@UserId, @Email, @FirstName, @LastName, @AzureAdB2CObjectId, 1)

        SELECT @UserId AS UserId, 'SUCCESS' AS Status
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        RAISERROR(@ErrorMessage, 16, 1)
    END CATCH
END

GO
/****** Object:  StoredProcedure [dbo].[usp_User_DevLogin]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_User_DevLogin]
    @Email NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON

    -- Return user WITHOUT password verification
    -- This allows instant login for testing
    SELECT
        UserId,
        Email,
        FirstName,
        LastName,
        RefreshToken,
        RefreshTokenExpiryDate,
        LastLoginDate,
        PhoneNumber,
        EmailConfirmed,
        MfaEnabled,
        AzureAdB2CObjectId,
        IsActive,
        CreatedDate,
        ModifiedDate
    FROM dbo.Users
    WHERE Email = @Email AND IsActive = 1

    -- Update last login
    UPDATE dbo.Users
    SET LastLoginDate = GETUTCDATE()
    WHERE Email = @Email AND IsActive = 1
END

GO
/****** Object:  StoredProcedure [dbo].[usp_User_GetByEmail]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_User_GetByEmail]
    @Email NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        UserId,
        Email,
        FirstName,
        LastName,
        PasswordHash,
        PasswordSalt,
        RefreshToken,
        RefreshTokenExpiryDate,
        LastLoginDate,
        PhoneNumber,
        EmailConfirmed,
        MfaEnabled,
        AzureAdB2CObjectId,
        IsActive,
        CreatedDate,
        ModifiedDate
    FROM dbo.Users
    WHERE Email = @Email AND IsActive = 1
END

GO
/****** Object:  StoredProcedure [dbo].[usp_User_GetById]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- Recreate with password fields
CREATE PROCEDURE [dbo].[usp_User_GetById]
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        UserId,
        Email,
        FirstName,
        LastName,
        PasswordHash,
        PasswordSalt,
        RefreshToken,
        RefreshTokenExpiryDate,
        LastLoginDate,
        PhoneNumber,
        EmailConfirmed,
        MfaEnabled,
        AzureAdB2CObjectId,
        IsActive,
        CreatedDate,
        ModifiedDate
    FROM dbo.Users
    WHERE UserId = @UserId
END

GO
/****** Object:  StoredProcedure [dbo].[usp_User_GetByRefreshToken]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_User_GetByRefreshToken]
    @RefreshToken NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        UserId,
        Email,
        FirstName,
        LastName,
        RefreshToken,
        RefreshTokenExpiryDate,
        LastLoginDate,
        PhoneNumber,
        EmailConfirmed,
        MfaEnabled,
        IsActive,
        CreatedDate,
        ModifiedDate
    FROM dbo.Users
    WHERE RefreshToken = @RefreshToken
        AND RefreshTokenExpiryDate > GETUTCDATE()
        AND IsActive = 1
END

GO
/****** Object:  StoredProcedure [dbo].[usp_User_GetRoles]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_User_GetRoles]
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON

    -- Get system roles
    SELECT
        'System' AS RoleType,
        NULL AS TenantId,
        sr.RoleName,
        sr.Description,
        usr.IsActive
    FROM dbo.UserSystemRoles usr
    INNER JOIN dbo.SystemRoles sr ON usr.SystemRoleId = sr.SystemRoleId
    WHERE usr.UserId = @UserId AND usr.IsActive = 1

    UNION ALL

    -- Get tenant roles
    SELECT
        'Tenant' AS RoleType,
        utr.TenantId,
        utr.RoleName,
        t.CompanyName AS Description,
        utr.IsActive
    FROM dbo.UserTenantRoles utr
    INNER JOIN dbo.Tenants t ON utr.TenantId = t.TenantId
    WHERE utr.UserId = @UserId AND utr.IsActive = 1
    ORDER BY RoleType, RoleName
END

GO
/****** Object:  StoredProcedure [dbo].[usp_User_Register]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_User_Register]
    @Email NVARCHAR(256),
    @FirstName NVARCHAR(100),
    @LastName NVARCHAR(100),
    @PasswordHash NVARCHAR(500),
    @PasswordSalt NVARCHAR(500),
    @PhoneNumber NVARCHAR(20) = NULL,
    @UserId UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    -- Check if email already exists
    IF EXISTS (SELECT 1 FROM dbo.Users WHERE Email = @Email AND IsActive = 1)
    BEGIN
        RAISERROR('User with this email already exists', 16, 1)
        RETURN
    END

    -- Create new user
    SET @UserId = NEWID()

    INSERT INTO dbo.Users (
        UserId,
        Email,
        FirstName,
        LastName,
        PasswordHash,
        PasswordSalt,
        PhoneNumber,
        EmailConfirmed,
        IsActive,
        CreatedDate,
        ModifiedDate
    )
    VALUES (
        @UserId,
        @Email,
        @FirstName,
        @LastName,
        @PasswordHash,
        @PasswordSalt,
        @PhoneNumber,
        0, -- Email not confirmed by default
        1,
        GETUTCDATE(),
        GETUTCDATE()
    )

    -- Return the created user
    SELECT
        UserId,
        Email,
        FirstName,
        LastName,
        PhoneNumber,
        EmailConfirmed,
        MfaEnabled,
        IsActive,
        CreatedDate,
        ModifiedDate
    FROM dbo.Users
    WHERE UserId = @UserId
END

GO
/****** Object:  StoredProcedure [dbo].[usp_User_UpdateLastLogin]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_User_UpdateLastLogin]
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON

    UPDATE dbo.Users
    SET
        LastLoginDate = GETUTCDATE(),
        ModifiedDate = GETUTCDATE()
    WHERE UserId = @UserId

    SELECT @@ROWCOUNT AS RowsAffected
END

GO
/****** Object:  StoredProcedure [dbo].[usp_User_UpdatePassword]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_User_UpdatePassword]
    @UserId UNIQUEIDENTIFIER,
    @PasswordHash NVARCHAR(500),
    @PasswordSalt NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON

    UPDATE dbo.Users
    SET
        PasswordHash = @PasswordHash,
        PasswordSalt = @PasswordSalt,
        ModifiedDate = GETUTCDATE()
    WHERE UserId = @UserId

    SELECT @@ROWCOUNT AS RowsAffected
END

GO
/****** Object:  StoredProcedure [dbo].[usp_User_UpdateRefreshToken]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_User_UpdateRefreshToken]
    @UserId UNIQUEIDENTIFIER,
    @RefreshToken NVARCHAR(500),
    @RefreshTokenExpiryDate DATETIME2
AS
BEGIN
    SET NOCOUNT ON

    UPDATE dbo.Users
    SET
        RefreshToken = @RefreshToken,
        RefreshTokenExpiryDate = @RefreshTokenExpiryDate,
        ModifiedDate = GETUTCDATE()
    WHERE UserId = @UserId

    SELECT @@ROWCOUNT AS RowsAffected
END

GO
/****** Object:  StoredProcedure [dbo].[usp_UserTenantRole_Assign]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_UserTenantRole_Assign]
    @UserId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER,
    @RoleName NVARCHAR(50),
    @AssignedByUserId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        -- Check if role assignment already exists
        IF EXISTS (
            SELECT 1 FROM dbo.UserTenantRoles
            WHERE UserId = @UserId
            AND TenantId = @TenantId
            AND RoleName = @RoleName
            AND IsActive = 1
        )
        BEGIN
            SELECT 'ROLE_EXISTS' AS Status
            RETURN
        END

        DECLARE @RoleId UNIQUEIDENTIFIER = NEWID()

        INSERT INTO dbo.UserTenantRoles (UserTenantRoleId, UserId, TenantId, RoleName, IsActive)
        VALUES (@RoleId, @UserId, @TenantId, @RoleName, 1)

        -- Log audit event
        INSERT INTO dbo.AuditLog (TenantId, UserId, Action, EntityType, EntityId, NewValues)
        VALUES (@TenantId, @AssignedByUserId, 'AssignRole', 'UserTenantRole',
                CAST(@RoleId AS NVARCHAR(36)),
                '{"UserId":"' + CAST(@UserId AS NVARCHAR(36)) + '","RoleName":"' + @RoleName + '"}')

        SELECT 'SUCCESS' AS Status, @RoleId AS UserTenantRoleId
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        RAISERROR(@ErrorMessage, 16, 1)
    END CATCH
END

GO
/****** Object:  StoredProcedure [dbo].[usp_UserTenantRole_GetByUser]    Script Date: 10/17/2025 3:11:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_UserTenantRole_GetByUser]
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        utr.UserTenantRoleId,
        utr.UserId,
        utr.TenantId,
        utr.RoleName,
        utr.IsActive,
        utr.CreatedDate,
        t.TenantCode,
        t.CompanyName,
        t.DatabaseSchema
    FROM dbo.UserTenantRoles utr
    INNER JOIN dbo.Tenants t ON utr.TenantId = t.TenantId
    WHERE utr.UserId = @UserId
    AND utr.IsActive = 1
    AND t.IsActive = 1
    ORDER BY t.CompanyName, utr.RoleName
END

GO
