	DECLARE @tableName varchar(200)
	DECLARE @columnName varchar(200)
	DECLARE @nullable varchar(50)
	DECLARE @datatype varchar(50)
	DECLARE @maxlen int
	DECLARE @pos int
	DECLARE @default varchar(250)
	DECLARE @sType varchar(50)
	DECLARE @sProperty varchar(200)

	DECLARE table_cursor CURSOR FOR SELECT TABLE_NAME FROM [INFORMATION_SCHEMA].[TABLES] WHERE TABLE_SCHEMA <> 'sys' ORDER BY TABLE_NAME

	OPEN table_cursor

	FETCH NEXT FROM table_cursor 
	INTO @tableName

	PRINT 'using System;'
	PRINT 'using System.ComponentModel.DataAnnotations;'
	PRINT ''
	PRINT 'namespace ' + 'MyProject.Models' --  <<--- SET YOUR CLASS NAMESPACE HERE
	PRINT '{'

	WHILE @@FETCH_STATUS = 0
	BEGIN

		PRINT 'public partial class ' + @tableName + ' {'

		DECLARE column_cursor CURSOR FOR 
		SELECT 
			COLUMN_NAME, 
			IS_NULLABLE, DATA_TYPE, 
			ISNULL(CHARACTER_MAXIMUM_LENGTH,'-1'), 
			ORDINAL_POSITION,COLUMN_DEFAULT 
		FROM 
			[INFORMATION_SCHEMA].[COLUMNS]  
		WHERE 
			[TABLE_NAME] = @tableName 
		ORDER BY 
			[ORDINAL_POSITION]

		OPEN column_cursor
			FETCH NEXT FROM column_cursor INTO @columnName, @nullable, @datatype, @maxlen, @pos, @default

			WHILE @@FETCH_STATUS = 0
			BEGIN

				-- Set the Data Type
				SELECT @sType = CASE @datatype
					WHEN 'int' THEN 'int'
					WHEN 'decimal' THEN 'Decimal'
					WHEN 'money' THEN 'Decimal'
					WHEN 'char' THEN 'string'
					WHEN 'nchar' THEN 'string'
					WHEN 'varchar' THEN 'string'
					WHEN 'nvarchar' THEN 'string'
					WHEN 'uniqueidentifier' THEN 'Guid'
					WHEN 'datetime' THEN 'DateTime'
					WHEN 'datetime2' THEN 'DateTime'
					WHEN 'bit' THEN 'bool'
					ELSE 'String'
				END

				-- Set Nullable Properties
				IF ((@sType = 'int' OR @sType = 'DateTime' OR @sType = 'bool') AND @nullable = 'YES')
					 SET @sType =  @sType + '?'
				
				-- If this is the first column, add [KEY] attribute
				If (@pos = 1)
					PRINT '[Key]'

				SELECT @sProperty = 'public ' + @sType + ' ' + @columnName + ' { get; set;}'
			
				-- Cleanup the Default Value
				SET @default = REPLACE(@default, '))', '')
				SET @default = REPLACE(@default, '((', '')

				-- Set Non-Nullallable INT Default Value
				If (@nullable = 'NO' AND @sType = 'int' AND @default <> '')
					SET @sProperty = @sProperty + ' = ' + @default + ';'

				-- Set Non-Nullable DateTime Default Value
				If (@nullable = 'NO' AND @sType = 'DateTime')
					SET @sProperty = @sProperty + ' = DateTime.UtcNow;' -- <<----- CHANGE IF NOT USING UTC 

				-- Set Non-Nullallable Bit Default Value
				If (@nullable = 'NO' AND @sType = 'bool')
				BEGIN
					IF (@default = '1')
						SET @sProperty = @sProperty + ' = true;'

					IF (@default = '0')
						SET @sProperty = @sProperty + ' = false;'
				END
					   
				PRINT @sProperty

				FETCH NEXT FROM column_cursor INTO @columnName, @nullable, @datatype, @maxlen, @pos, @default
			END
		CLOSE column_cursor
		DEALLOCATE column_cursor

		PRINT '}'
		FETCH NEXT FROM table_cursor 
		INTO @tableName
	END
	PRINT '}'
	CLOSE table_cursor
	DEALLOCATE table_cursor
