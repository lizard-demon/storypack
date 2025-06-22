#!/usr/bin/env lua

for dir in io.popen("find packages -type d"):lines() do
   package.path = dir .. "/?.lua;" .. dir .. "/?/init.lua;" .. package.path
end

--------------------------------------------------------------------------------
-- pack - pack stories --
--
--  A declaritive rolling release
--  source based package manager
--  for stories - written in lua.
--

stories = os.getenv("HOME") .. "/.Library"

--------------------------------------------------------------------------------
-- Packs -> require("<packer>.<author>.<story>")

-- require("nop")               -- NOP Story Packer
-- require("nop.cannon")        -- All Cannon
-- require("nop.cannon.main")   -- Main Stories
-- require("nop.cannon.main.1") -- Main Story 1
-- require("nop.cannon.main.2") -- Main Story 2
-- require("nop.cannon.arxur")  -- Side Story

-- require("nop.heroman3003")                         -- All Heroman Stories
-- require("nop.heroman3003.waywardodysee")           -- Heroman Story
-- require("nop.heroman3003.takingcareofbrokenbirds") -- Heroman Story 

-- require("ao3")                      -- AO3 Story Packer
-- require("ao3.tgweaver")             -- All TGWeaver Stories
-- require("ao3.tgweaver.packstreet")  -- Single Story
-- etc... --

--------------------------------------------------------------------------------
-- Packers -> require("<packer>") { ... }

-- DDL, Download File
require("ddl") {
  url = "https://archiveofourown.org/downloads/12141837/Pack_Street.epub",
  path = stories .. "/Pack_Street.epub",
}

-- Sync, Sync File
require("sync") {
  url = "https://archiveofourown.org/downloads/23265703/Serval_Sheep_Sophomore.epub",
  path = stories .. "/Serval_Sheep_Sophomore.epub",
}

-- AO3, Sync to AO3
require("ao3") {
  url = "https://archiveofourown.org/works/25378225/chapters/61757572",
  dir = stories,
}

--
-- Packers as a standard use hidden sidecar files
-- /example/file.txt -> /example/.file.txt.<ext>
--
