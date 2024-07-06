CREATE   PROCEDURE MTG.GetSets
    @UserID int = -1
AS
BEGIN
    SET NOCOUNT ON

    IF @UserID = -1
    BEGIN
        SELECT [id], [name], [shorthand], [icon], [search_uri], [set_type_id], [source_id], [release_date] 
        FROM [MTG].[Set]
        RETURN
    END

    DROP TABLE IF EXISTS #settingsTemp
    DROP TABLE IF EXISTS #setTypes
    DROP TABLE IF EXISTS #setIds
    DROP TABLE IF EXISTS #setsOutput

    SELECT [Key], [Value]
    INTO #settingsTemp
    FROM [TCGCT].[Settings] AS s
    JOIN [TCGCT].[Games] AS g ON g.Name = 'MTG'
    WHERE s.UserID = @UserID AND s.GameID = g.ID AND [Key] IN ('FilterBySetIDs', 'FilterBySetTypes')

    SELECT ss.[value]
    INTO #setTypes
    FROM #settingsTemp AS st
    CROSS APPLY (
        SELECT [value] FROM STRING_SPLIT(st.[Value], ',')
    ) AS ss
    WHERE st.[Key] = 'FilterBySetTypes'

    SELECT ss.[value]
    INTO #setIds
    FROM #settingsTemp AS st
    CROSS APPLY (
        SELECT [value] FROM STRING_SPLIT(st.[Value], ',')
    ) AS ss
    WHERE st.[Key] = 'FilterBySetIDs'

    SELECT s.[id], s.[name], s.[shorthand], s.[icon], s.[search_uri], s.[set_type_id], s.[source_id], s.[release_date] 
    INTO #setsOutput
    FROM MTG.[Set] AS s

    IF EXISTS(SELECT TOP(1) 1 FROM #setIds)
    BEGIN
        DELETE so
        FROM #setsOutput AS so
        WHERE so.id NOT IN (SELECT si.[value] FROM #setIds AS si)
    END

    IF EXISTS(SELECT TOP(1) 1 FROM #setTypes)
    BEGIN
        DELETE so
        FROM #setsOutput AS so
        WHERE so.set_type_id NOT IN (SELECT st.[value] FROM #setTypes AS st)
    END

    SELECT so.[id], so.[name], so.[shorthand], so.[icon], so.[search_uri], so.[set_type_id], so.[source_id], so.[release_date], ISNULL(ps.SetID, 0) AS Pinned
    FROM #setsOutput AS so
    LEFT JOIN [MTG].[PinnedSet] AS ps ON ps.SetID = so.id AND ps.UserID = @UserID
END
GO

