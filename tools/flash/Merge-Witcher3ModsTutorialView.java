import java.io.*;
import java.util.*;
import com.jpexs.decompiler.flash.SWF;
import com.jpexs.decompiler.flash.abc.ABC;
import com.jpexs.decompiler.flash.abc.ScriptPack;
import com.jpexs.decompiler.flash.tags.*;
import com.jpexs.decompiler.flash.tags.base.*;

// Offline asset transfer only. Keep the tutorial document, timeline and shared
// engine classes; import journal presentation symbols without its menu root.
class MergeWitcher3ModsTutorialView {
    static final String ROOT = "red.game.witcher3.menus.journal.QuestJournalMenu";
    static ABC abc(SWF movie) {
        List<ABC> found = new ArrayList<>();
        for (Tag tag : movie.getTags()) if (tag instanceof DoABC2Tag code) found.add(code.getABC());
        if (found.size() != 1) throw new IllegalStateException("Expected one ABC per native movie");
        return found.get(0);
    }
    static Set<String> classes(SWF movie) {
        Set<String> result = new HashSet<>();
        for (ScriptPack pack : movie.getAS3Packs()) {
            if (!result.add(pack.getClassPath().toString())) throw new IllegalStateException("Duplicate script " + pack.getClassPath());
        }
        return result;
    }
    static void exposeListFrame(SWF host) {
        // The tutorial's left border is root artwork, not part of its module.
        // Give its native shape a named sprite without changing native geometry.
        // Match bounds, never an unstable exported character ID.
        PlaceObject2Tag frame = null;
        for (Tag tag : host.getTags()) if (tag instanceof PlaceObject2Tag place && !place.placeFlagHasName && host.getCharacter(place.characterId) instanceof ShapeTag shape) {
            var bounds = shape.getRect();
            if (bounds.Xmin == 1680 && bounds.Xmax == 13300 && bounds.Ymin == 4400 && bounds.Ymax == 10600) {
                if (frame != null) throw new IllegalStateException("Ambiguous tutorial list frame");
                frame = place;
            }
        }
        if (frame == null || frame.matrix.translateX != 0 || frame.matrix.translateY != 0 || frame.matrix.hasScale || frame.matrix.hasRotate) throw new IllegalStateException("Native tutorial list frame changed");
        DefineSpriteTag wrapper = new DefineSpriteTag(host);
        wrapper.spriteId = host.getNextCharacterId();
        wrapper.frameCount = 1;
        PlaceObject2Tag artwork = new PlaceObject2Tag(host);
        artwork.setCharacterId(frame.characterId);
        artwork.setDepth(1);
        artwork.setMatrix(new com.jpexs.decompiler.flash.types.MATRIX());
        wrapper.addTag(artwork);
        wrapper.addTag(new ShowFrameTag(host));
        host.addTag(host.indexOfTag(frame), wrapper);
        frame.setCharacterId(wrapper.spriteId);
        frame.setInstanceName("Witcher3ModsNativeListFrame");
        frame.setModified(true);
        host.updateCharacters();
    }
    public static void main(String[] args) throws Exception {
        if (args.length != 3) throw new IllegalArgumentException("tutorial.swf patched-journal.swf output.swf");
        SWF host;
        SWF donor;
        try (InputStream input = new FileInputStream(args[0])) { host = new SWF(input, false); }
        try (InputStream input = new FileInputStream(args[1])) { donor = new SWF(input, false); }
        if (!host.getDocumentClass().equals("red.game.witcher3.menus.glossary.GlossaryTutorialsMenu")) throw new IllegalStateException("Wrong host");
        exposeListFrame(host);
        Set<String> nativeClasses = classes(host);
        ABC donorCode = abc(donor);
        Map<String,String> renames = new LinkedHashMap<>();
        // Isolate global linkage classes, including names looked up dynamically.
        for (Tag tag : donor.getTags()) if (tag instanceof SymbolClassTag symbols) {
            for (String name : symbols.names) if (!name.contains(".")) renames.put(name, "Witcher3Mods" + name);
        }
        for (String name : List.of("TextAreaModule", "TextAreaModuleCustomInput", "QuestItemRenderer", "ObjectiveItemRenderer")) renames.put(name, "Witcher3Mods" + name);
        // These native event receivers exist on the tutorial/list base classes.
        renames.put("OnTrackQuest", "OnEntryPress");
        renames.put("OnHighlightObjective", "OnEntryPress");
        renames.put("OnObjectiveRead", "OnEntryRead");
        for (int i = 1; i < donorCode.constants.getStringCount(); i++) {
            String original = donorCode.constants.getString(i);
            if (renames.containsKey(original)) donorCode.constants.setString(i, renames.get(original));
        }
        donorCode.constants.clearCachedMultinames();
        donorCode.constants.clearCachedDottedChains();
        // Deletion is by script identity, before packing/remapping indices.
        for (ScriptPack pack : new ArrayList<ScriptPack>(donor.getAS3Packs())) {
            String name = pack.getClassPath().toString();
            if (nativeClasses.contains(name) || name.equals(ROOT)) pack.delete(donorCode, true);
        }
        donorCode.pack();
        donorCode.clearPacksCache();
        donor.clearScriptCache();
        Set<String> importedClasses = classes(donor);
        if (importedClasses.contains(ROOT)) throw new IllegalStateException("Journal menu root retained");
        for (String name : importedClasses) if (nativeClasses.contains(name)) throw new IllegalStateException("Shared engine class duplicated: " + name);

        int offset = host.getNextCharacterId() + donor.getNextCharacterId();
        List<Integer> ids = new ArrayList<>(donor.getCharacters(false).keySet());
        ids.sort(Comparator.reverseOrder());
        if (offset + Collections.max(ids) > 65535) throw new IllegalStateException("Character ID overflow");
        int insert = 0;
        for (Tag tag : host.getTags()) { if (tag instanceof ShowFrameTag) break; insert++; }
        int transferred = 0;
        for (Tag tag : donor.getTags()) {
            if (!(tag instanceof CharacterTag || tag instanceof DefineScalingGridTag || tag.getClass().getSimpleName().equals("CSMSettingsTag") || tag instanceof DefineFontNameTag || tag instanceof DefineFontAlignZonesTag)) continue;
            Tag copy = tag.cloneTag();
            int ownId = tag instanceof CharacterIdTag character ? character.getCharacterId() : -1;
            for (int id : ids) copy.replaceCharacter(id, id + offset);
            if (copy instanceof CharacterIdTag character && ownId > 0) character.setCharacterId(ownId + offset);
            copy.setSwf(host, true);
            copy.setTimelined(host);
            copy.setModified(true);
            host.addTag(insert++, copy);
            transferred++;
        }
        SymbolClassTag importedSymbols = new SymbolClassTag(host);
        for (Tag tag : donor.getTags()) if (tag instanceof SymbolClassTag symbols) {
            for (int i = 0; i < symbols.tags.size(); i++) {
                int id = symbols.tags.get(i);
                if (id == 0) continue;
                String name = symbols.names.get(i);
                name = renames.getOrDefault(name, name);
                importedSymbols.tags.add(id + offset);
                importedSymbols.names.add(name);
            }
        }
        abc(host).mergeABC(donorCode);
        ((Tag)abc(host).parentTag).setModified(true);
        host.addTag(insert, importedSymbols);
        host.updateCharacters();
        host.assignClassesToSymbols();
        Set<String> finalClasses = classes(host);
        if (finalClasses.size() != nativeClasses.size() + importedClasses.size()) throw new IllegalStateException("Class inventory mismatch");
        for (String name : List.of("Witcher3ModsMC_MODULE_QuestList", "Witcher3ModsMC_MODULE_ObjectiveList", "Witcher3ModsMC_MODULE_TextAreaLegend")) {
            if (host.getCharacterByClass(name) == null) throw new IllegalStateException("Missing module symbol " + name);
        }
        for (Tag tag : host.getTags()) if (tag instanceof CharacterTag) {
            Set<Integer> required = new HashSet<>();
            tag.getNeededCharacters(required, new HashSet<String>(), host);
            for (int id : required) if (id > 0 && id != 65535 && host.getCharacter(id) == null) {
                throw new IllegalStateException("Unresolved asset reference " + id + " in " + tag);
            }
        }
        try (OutputStream output = new FileOutputStream(args[2])) { host.saveTo(output); }
        System.out.println("Tutorial host retained; imported " + transferred + " presentation assets and " + importedClasses.size() + " isolated classes; no JournalQuestMenu root.");
    }
}
