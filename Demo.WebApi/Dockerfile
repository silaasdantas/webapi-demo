# Step 1: Use a base image with ASP.NET runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443  

# Step 2: Use the SDK image to build the app
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["Demo.WebApi.csproj", "./"]
RUN dotnet restore "Demo.WebApi.csproj"
COPY . .
WORKDIR "/src"
RUN dotnet build "Demo.WebApi.csproj" -c Release -o /app/build

# Step 3: Publish the app
FROM build AS publish
RUN dotnet publish "Demo.WebApi.csproj" -c Release -o /app/publish

# Step 4: Create the final image
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Demo.WebApi.dll"]