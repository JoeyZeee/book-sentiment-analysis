clear all;
chapter_labels = ["ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTEEN", "NINETEEN", "TWENTY", "TWENTY-ONE", "TWENTY-TWO", "TWENTY-THREE", "TWENTY-FOUR", "TWENTY-FIVE", "TWENTY-SIX", "THEEND"];
character_labels = ["starr", "khalil", "daddy", "momma"];
lexicon_files = ["anger", "anticipation", "disgust", "fear", "joy", "sadness", "surprise", "trust"];
lexicon_files_suffix = "-NRC-Emotion-Intensity-Lexicon-v1.txt";

% Read from file, get entire text
txt = extractFileText('2018 honor The Hate U Give Thomas.txt');

chapter_sentiment = zeros(length(chapter_labels)-1, length(character_labels), length(lexicon_files));

%for contextLength = 5:10:55
contextLength = 25;

% Read in the lexicon files
for lexicon=1:length(lexicon_files)
    lexicon_tables{lexicon} = readtable("lexicons/"+lexicon_files(lexicon)+lexicon_files_suffix);
    lexicon_tables{lexicon} = renamevars(lexicon_tables{lexicon},["word","val"],["Token","SentimentScore"]);

    % Verify there's no empty rows in the file so that validateNgram passes
    % later in vaderSentimentScores
    ngram = string(lexicon_tables{lexicon}.Token);
    wrongempty = (ngram == '' | ismissing(ngram));
    if (sum(wrongempty) ~= 0)
        disp("Found empty row in " + lexicon_files{lexicon});
        emptyrows = find(wrongempty == 1);
        disp(emptyrows(1));
    end

end

for chapter=1:length(chapter_labels)-1

    disp("Analyzing chapter " + chapter_labels(chapter))
    % Grab the current chapter
    chapter_txt = extractBetween(txt, chapter_labels(chapter), chapter_labels(chapter+1));
    chapter_txt = chapter_txt(1,:);

    % Erase punctuation.
    chapter_txt2 = erasePunctuation(chapter_txt);
    % Split line by line
    chapter_txt3 = split(chapter_txt2,newline);
    
    % Remove blank lines
    chapter_txt3(cellfun('isempty',chapter_txt3)) = [];
    
    % Convert to tokens
    tokens = tokenizedDocument(chapter_txt3);
    
    
    % Remove a list of stop words.
    tokens = removeStopWords(tokens);
    
    % Normalize tokens (or convert to lower)
    %tokens = normalizeWords(tokens,'Style','lemma');
    tokens = lower(tokens);

    for character=1:length(character_labels)
        disp("   Character '" + character_labels(character) + "'");
        % Ngrams for each character name. Needs further analysis
        chapter_context = context(tokens, character_labels(character), contextLength);
        chapter_tokens = tokenizedDocument(chapter_context.Context);
        %[positive_sentiment(chapter, character), negative_sentiment(chapter, character)] = vaderSentimentScores(chapter_tokens)
        %[compoundScores,positiveScores,negativeScores,neutralScores] = vaderSentimentScores(chapter_tokens)

        for lexicon=1:length(lexicon_files)
            disp("   Lexicon '" + lexicon_files(lexicon) + "'");        
            compoundScores = vaderSentimentScores(chapter_tokens, 'SentimentLexicon',lexicon_tables{lexicon});
            chapter_sentiment(chapter, character, lexicon) = mean(compoundScores);%mean(compoundScores(compoundScores~=0));%sum(compoundScores);
        end

    end

    disp("DONE");
end

for character=1:length(character_labels)
    figs(character) = figure; hold on;
    figs(character).WindowState = 'maximized';
    for lexicon=1:length(lexicon_files)
        if (lexicon > length(lexicon_files)/2)
            plot(chapter_sentiment(:,character,lexicon), 'o--', 'LineWidth', 3);
        else
            plot(chapter_sentiment(:,character,lexicon), 'o-', 'LineWidth', 3);
        end
    end
    xlim([0,length(chapter_labels)])
    xticks(1:length(chapter_labels)-1)
    xticklabels(chapter_labels(1:length(chapter_labels)-1));    
    legend(lexicon_files)
    title("Analysis of " + character_labels(character), 'Interpreter', 'none');
    saveas(figs(character), "character_analysis_NRC_emotion_"+character_labels(character), 'png');
end
